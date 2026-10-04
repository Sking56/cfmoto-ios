import Foundation
import Network
import OpenCFMotoCore
import XCTest
@testable import ProtocolHarness

// Like HostProbe, this fake is confined to the probe callback queue.
private final class HeldTransport: @unchecked Sendable {
    var completions: [@Sendable (NWError?) -> Void] = []
    var sent: [Data] = []

    func send(_ bytes: Data, completion: @escaping @Sendable (NWError?) -> Void) {
        sent.append(bytes); completions.append(completion)
    }

    func complete(_ error: NWError? = nil) { completions.removeFirst()(error) }
}

final class HostProbeTests: XCTestCase {
    func testInvalidLibraryConfigurationFailsWithoutIndexingOrOpeningSockets() {
        for ports: [UInt16] in [[], [1, 2, 3], [0, 2, 3, 4], [1, 1, 3, 4]] {
            XCTAssertFalse(HostProbe(ports: ports).run())
        }
    }

    private func configured(_ transport: HeldTransport) throws -> (HostProbe, Peer) {
        let probe = HostProbe(ports: [10930, 10922, 10921, 10920], sendOperation: { _, bytes, completion in
            transport.send(bytes, completion: completion)
        })
        let peer = try Peer(connection: NWConnection(host: .ipv4(.loopback), port: 10920, using: .tcp),
                            format: .media, channel: .mediaData)
        try probe.queue.sync {
            let generation = probe.state.begin()
            try probe.state.acceptWake(generation: generation)
            for evidence in HandshakeEvidence.allCases { try probe.state.record(evidence, generation: generation) }
            probe.peers.append(peer)
        }
        return (probe, peer)
    }

    func testPullWaitsForHeldAcknowledgementBeforeSuccess() throws {
        let transport = HeldTransport()
        let (probe, peer) = try configured(transport)
        try probe.queue.sync {
            try probe.handle(.media(MediaFrame(command: 112)), from: peer)
            try probe.handle(.media(MediaFrame(command: 114)), from: peer)
            probe.finishIfDrained()
            XCTAssertFalse(probe.complete)
            XCTAssertTrue(probe.pullObserved)
            XCTAssertEqual(peer.writer.pendingWriteCount, 1)
            XCTAssertEqual(transport.sent, [try MediaFrame(command: 113).encoded()])
            transport.complete()
            XCTAssertTrue(probe.complete); XCTAssertTrue(probe.success)
            XCTAssertEqual(peer.writer.pendingWriteCount, 0)
        }
    }

    func testLateCompletionAfterTeardownCannotReportSuccessOrReopenWriter() throws {
        let transport = HeldTransport()
        let (probe, peer) = try configured(transport)
        try probe.queue.sync {
            try probe.handle(.media(MediaFrame(command: 112)), from: peer)
            try probe.handle(.media(MediaFrame(command: 114)), from: peer)
            probe.finishIfDrained()
            XCTAssertFalse(probe.complete)
            probe.finish(false, reason: "testTeardown")
            let stoppedGeneration = probe.state.generation
            transport.complete()
            XCTAssertTrue(probe.complete); XCTAssertFalse(probe.success)
            XCTAssertEqual(probe.state.state, .idle)
            XCTAssertEqual(probe.state.generation, stoppedGeneration)
            XCTAssertEqual(peer.writer.pendingWriteCount, 0)
            XCTAssertNil(peer.writer.next())
            XCTAssertThrowsError(try peer.writer.enqueue([Data([1])])) { XCTAssertEqual($0 as? WriteQueueError, .closed) }
        }
    }

    func testCurrentSendFailureWinsOverObservedPull() throws {
        let transport = HeldTransport()
        let (probe, peer) = try configured(transport)
        try probe.queue.sync {
            try probe.handle(.media(MediaFrame(command: 112)), from: peer)
            try probe.handle(.media(MediaFrame(command: 114)), from: peer)
            transport.complete(.posix(.ECONNRESET))
            XCTAssertTrue(probe.complete); XCTAssertFalse(probe.success)
            XCTAssertEqual(peer.writer.pendingWriteCount, 0)
        }
    }

    func testEveryConnectionMustDrainBeforeSuccess() throws {
        let transport = HeldTransport()
        let (probe, peer) = try configured(transport)
        try probe.queue.sync {
            let control = try Peer(connection: NWConnection(host: .ipv4(.loopback), port: 10922, using: .tcp),
                                   format: .pxc, channel: .pxcControl)
            probe.peers.append(control)
            try probe.handle(.media(MediaFrame(command: 112)), from: peer)
            try probe.handle(.pxc(PXCFrame(command: 0x70000000)), from: control)
            try probe.handle(.media(MediaFrame(command: 114)), from: peer)
            transport.complete()
            XCTAssertFalse(probe.complete)
            transport.complete()
            XCTAssertTrue(probe.complete); XCTAssertTrue(probe.success)
        }
    }
}
