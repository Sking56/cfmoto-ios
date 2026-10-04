import Foundation
import XCTest
@testable import OpenCFMotoCore

final class WireCodecTests: XCTestCase {
    struct Manifest: Decodable {
        struct Entry: Decodable {
            struct Expected: Decodable { let rejection: String? }
            let path: String; let wire: String; let expected: Expected
        }
        let fixtures: [Entry]
    }

    func testAllValidFixturesEncodeByteForByteAtEverySplit() throws {
        let manifest = try JSONDecoder().decode(Manifest.self, from: fixture("protocol-manifest.json"))
        for item in manifest.fixtures where item.expected.rejection == nil {
            let bytes = try fixture(item.path)
            let format = try XCTUnwrap(WireFormat(rawValue: item.wire))
            for split in 0...bytes.count {
                var decoder = try StreamDecoder(format: format)
                let frames = try decoder.append(Data(bytes.prefix(split))) + decoder.append(Data(bytes.dropFirst(split)))
                XCTAssertEqual(frames.count, 1, item.path)
                XCTAssertEqual(try frames[0].encoded(), bytes, item.path)
                XCTAssertEqual(decoder.bufferedByteCount, 0)
                try decoder.finish()
            }
        }
    }

    func testAllNegativeFixturesAndTerminalFailure() throws {
        let manifest = try JSONDecoder().decode(Manifest.self, from: fixture("protocol-manifest.json"))
        let errors: [String: ProtocolError] = ["incomplete": .truncatedFrame, "bad-xor": .badChecksum,
            "undersized-total": .invalidLength, "size-guard": .frameTooLarge]
        for item in manifest.fixtures {
            guard let rejection = item.expected.rejection else { continue }
            var decoder = try StreamDecoder(format: XCTUnwrap(WireFormat(rawValue: item.wire)))
            let bytes = try fixture(item.path)
            XCTAssertThrowsError(try { _ = try decoder.append(bytes); try decoder.finish() }()) {
                XCTAssertEqual($0 as? ProtocolError, errors[rejection], item.path)
            }
            XCTAssertThrowsError(try decoder.append(Data())) { XCTAssertEqual($0 as? ProtocolError, .streamTerminated) }
            XCTAssertEqual(decoder.bufferedByteCount, 0)
        }
    }

    func testCoalescedMessagesPartialTailAndOneByteReads() throws {
        let frame = try fixture("handshake/car-ctrl-select.bin")
        let body = try fixture("handshake/check-sn-request.bin")
        var decoder = try StreamDecoder(format: .pxc)
        let joined = frame + body + Data(frame.prefix(3))
        XCTAssertEqual(try decoder.append(joined).count, 2)
        XCTAssertEqual(decoder.bufferedByteCount, 3)
        XCTAssertEqual(try decoder.append(Data(frame.dropFirst(3))).count, 1)
        try decoder.finish()
        var byteDecoder = try StreamDecoder(format: .pxc)
        var count = 0
        for byte in frame + body { count += try byteDecoder.append(Data([byte])).count }
        XCTAssertEqual(count, 2)
        try byteDecoder.finish()
    }

    func testReservedUnknownCommandSignedMediaAndNonzeroToken() throws {
        let unknown = PXCFrame(command: 0xffffffff, body: Data([1, 2]), reserved: 0x87654321)
        var pxc = try StreamDecoder(format: .pxc)
        XCTAssertEqual(try pxc.append(unknown.encoded()), [.pxc(unknown)])
        let media = MediaFrame(command: -1, body: Data([3]), token: Int32.min)
        var decoder = try StreamDecoder(format: .media)
        XCTAssertEqual(try decoder.append(media.encoded()), [.media(media)])
    }

    func testLimitsAtHeaderAndEncoderBoundaries() throws {
        XCTAssertThrowsError(try StreamDecoder(format: .pxc, maximumFrameBytes: 15))
        var decoder = try StreamDecoder(format: .pxc, maximumFrameBytes: 16)
        let packet = try PXCFrame(command: 1, body: Data([1])).encoded()
        XCTAssertThrowsError(try decoder.append(Data(packet.prefix(16)))) { XCTAssertEqual($0 as? ProtocolError, .frameTooLarge) }
        XCTAssertEqual(decoder.bufferedByteCount, 0)
        XCTAssertThrowsError(try PXCFrame(command: 1, body: Data([1])).encoded(maximumBytes: 16))
        let maximumMedia = MediaFrame(command: -32, body: Data(repeating: 1, count: 65535), token: -42)
        var media = try StreamDecoder(format: .media)
        XCTAssertEqual(try media.append(maximumMedia.encoded()), [.media(maximumMedia)])
        XCTAssertThrowsError(try MediaFrame(command: 1, body: Data(repeating: 0, count: 65536)).encoded())
        var raw = try StreamDecoder(format: .rawVideo)
        XCTAssertThrowsError(try raw.append(Data([0, 0, 0, 0]))) { XCTAssertEqual($0 as? ProtocolError, .invalidLength) }
    }

    func testDeterministicMalformedInputNeverTrapsOrExceedsLimit() throws {
        var seed: UInt64 = 0x450
        for format in [WireFormat.pxc, .media, .rawVideo] {
            for _ in 0..<500 {
                seed = seed &* 6364136223846793005 &+ 1
                let length = Int(seed % 128)
                var bytes = Data()
                for _ in 0..<length {
                    seed = seed &* 6364136223846793005 &+ 1
                    bytes.append(UInt8(truncatingIfNeeded: seed >> 32))
                }
                var decoder = try StreamDecoder(format: format, maximumFrameBytes: 256)
                do { _ = try decoder.append(bytes); try decoder.finish() } catch { XCTAssertTrue(error is ProtocolError) }
                XCTAssertLessThanOrEqual(decoder.bufferedByteCount, 256)
            }
        }
    }
}
