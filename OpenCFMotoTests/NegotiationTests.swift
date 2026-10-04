import Foundation
import XCTest
@testable import OpenCFMotoCore

final class NegotiationTests: XCTestCase {
    struct Identity: ClientIdentityProvider {
        func reply(toHUID huid: String) throws -> Data { Data("{\"profile\":\"synthetic-no-crypto\"}".utf8) }
    }

    func testWakeRequiresBooleanRatherThanSubstringOrNumber() throws {
        XCTAssertTrue(try Negotiator.wakeAccepted(PXCFrame(command: 0x70000011, body: Data("{\"status\":true}".utf8))))
        XCTAssertFalse(try Negotiator.wakeAccepted(PXCFrame(command: 0x70000011, body: Data("{\"status\":false,\"other\":\"true\"}".utf8))))
        for value in ["1", "\"true\"", "null"] {
            XCTAssertThrowsError(try Negotiator.wakeAccepted(PXCFrame(command: 0x70000011, body: Data("{\"status\":\(value)}".utf8))))
        }
        XCTAssertThrowsError(try Negotiator.wakeAccepted(PXCFrame(command: 1)))
    }

    func testKnownRepliesMatchIndependentFixturesAndTokenPolicy() throws {
        let negotiator = Negotiator(identity: Identity())
        let cases: [(String, String, SessionChannel)] = [
            ("handshake/car-ctrl-select.bin", "handshake/car-ctrl-ack.bin", .pxcControl),
            ("handshake/car-data-select.bin", "handshake/car-data-ack.bin", .pxcData),
            ("heartbeat/pxc-request.bin", "heartbeat/pxc-ack.bin", .pxcData),
            ("heartbeat/media-request.bin", "heartbeat/media-ack.bin", .mediaControl),
            ("capabilities/config-capture-request.bin", "capabilities/config-capture-reply.bin", .mediaControl),
            ("capabilities/version-request.bin", "capabilities/version-reply.bin", .mediaControl),
            ("capabilities/extend-request.bin", "capabilities/extend-reply.bin", .mediaControl),
            ("capabilities/start-h264-request.bin", "capabilities/start-h264-reply.bin", .mediaControl),
            ("video/data-start.bin", "video/data-start-ack.bin", .mediaData)
        ]
        for (request, reply, channel) in cases {
            var decoder = try StreamDecoder(format: request.contains("pxc") || request.contains("handshake") ? .pxc : .media)
            let frame = try XCTUnwrap(decoder.append(fixture(request)).first)
            let result = try negotiator.handle(frame, on: channel)
            XCTAssertEqual(result.replies.count, 1)
            XCTAssertEqual(try result.replies[0].encoded(), try fixture(reply))
        }
        let heartbeat = try negotiator.handle(.media(MediaFrame(command: 64, token: 123)), on: .mediaControl)
        XCTAssertEqual(heartbeat.replies, [.media(MediaFrame(command: 65, token: 0))])
    }

    func testSNUsesRequestIdentityAndNoGenericUnknownAcknowledgement() throws {
        var decoder = try StreamDecoder(format: .pxc)
        let frame = try XCTUnwrap(decoder.append(fixture("handshake/check-sn-request.bin")).first)
        let result = try Negotiator().handle(frame, on: .pxcControl)
        XCTAssertEqual(result.replies.count, 2)
        XCTAssertEqual(try result.replies[0].encoded(), try fixture("handshake/check-sn-ack.bin"))
        guard case .pxc(let reply) = result.replies[1] else { return XCTFail("Expected PXC") }
        let json = try JSONSerialization.jsonObject(with: reply.body) as? [String: Any]
        XCTAssertEqual(json?["id"] as? String, "SYNTHETIC-SN-0001")
        XCTAssertEqual(json?["isOk"] as? Bool, true)
        XCTAssertThrowsError(try Negotiator().handle(.pxc(PXCFrame(command: 0x33333)), on: .pxcControl))
        XCTAssertThrowsError(try Negotiator().handle(.pxc(PXCFrame(command: 0x10000)), on: .mediaControl))
    }

    func testIdentityFailsExplicitlyWhenProviderMissing() throws {
        var decoder = try StreamDecoder(format: .pxc)
        let frame = try XCTUnwrap(decoder.append(fixture("capabilities/client-info-request.bin")).first)
        XCTAssertThrowsError(try Negotiator().handle(frame, on: .pxcControl)) { XCTAssertEqual($0 as? ProtocolError, .identityUnavailable) }
        XCTAssertEqual(try Negotiator(identity: Identity()).handle(frame, on: .pxcControl).evidence, [.identity])
    }

    func testCaptureValidationBeforeReplyAndPullDoesNotFabricateFrame() throws {
        var decoder = try StreamDecoder(format: .media)
        guard case .media(let request) = try XCTUnwrap(decoder.append(fixture("capabilities/config-capture-request.bin")).first) else {
            return XCTFail("Expected media")
        }
        let config = try CaptureConfiguration(body: request.body)
        XCTAssertEqual(config.width, 800); XCTAssertEqual(config.height, 384); XCTAssertEqual(config.framesPerSecond, 30)
        for length in 0..<30 { XCTAssertThrowsError(try CaptureConfiguration(body: Data(request.body.prefix(length)))) }
        for (offset, bytes) in [(0, [UInt8(0), 0]), (4, [0, 0, 0, 0]), (8, [3, 0, 0, 0])] {
            var invalid = request.body; invalid.replaceSubrange(offset..<(offset + bytes.count), with: bytes)
            XCTAssertThrowsError(try CaptureConfiguration(body: invalid)) { XCTAssertEqual($0 as? ProtocolError, .unsupportedCapture) }
        }
        let pull = try Negotiator().handle(.media(MediaFrame(command: 114)), on: .mediaData)
        XCTAssertTrue(pull.requestsFrame); XCTAssertEqual(pull.replies, [])
        XCTAssertThrowsError(try Negotiator().handle(.media(MediaFrame(command: 114)), on: .mediaControl))
    }

    func testReadinessNeedsEveryExchangeAndIgnoresOldGenerations() throws {
        var state = SessionStateMachine()
        let first = state.begin()
        XCTAssertThrowsError(try state.record(.pxcControl, generation: first))
        try state.acceptWake(generation: first)
        for item in HandshakeEvidence.allCases.dropLast().reversed() {
            try state.record(item, generation: first)
            XCTAssertEqual(state.state, .negotiating)
        }
        try state.record(.pxcControl, generation: first)
        try state.record(.h264, generation: first)
        XCTAssertEqual(state.state, .ready)
        state.stop(); state.stop()
        try state.record(.h264, generation: first)
        try state.acceptWake(generation: first)
        state.fail(.timeout, generation: first)
        XCTAssertEqual(state.state, .idle); XCTAssertTrue(state.evidence.isEmpty)
        let second = state.begin()
        try state.acceptWake(generation: second)
        state.fail(.connectionLost, generation: second)
        state.fail(.timeout, generation: second)
        XCTAssertEqual(state.state, .failed(.connectionLost))
        XCTAssertThrowsError(try state.record(.h264, generation: second))
    }
}
