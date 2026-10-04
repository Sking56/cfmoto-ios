import Dispatch
import Foundation
import Network
import OpenCFMotoCore

struct SyntheticIdentity: ClientIdentityProvider {
    func reply(toHUID huid: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "profile": "synthetic-no-crypto", "phoneUUID": "SYNTHETIC-PHONE",
            "supportH264IFrame": true, "supportFunction": 0
        ], options: [.sortedKeys])
    }
}

// All mutable probe/peer state is confined to the single Network callback queue.
final class Peer: @unchecked Sendable {
    let connection: NWConnection
    var decoder: StreamDecoder
    var writer: WriteQueue
    var channel: SessionChannel?
    let isWake: Bool
    var started = false

    init(connection: NWConnection, format: WireFormat, channel: SessionChannel? = nil, isWake: Bool = false) throws {
        self.connection = connection; self.decoder = try StreamDecoder(format: format)
        self.writer = try WriteQueue()
        self.channel = channel; self.isWake = isWake
    }
}

final class HostProbe: @unchecked Sendable {
    let queue = DispatchQueue(label: "org.opencfmoto.host-probe")
    let done = DispatchSemaphore(value: 0)
    let ports: [UInt16]
    let negotiator = Negotiator(identity: SyntheticIdentity())
    var state = SessionStateMachine()
    var listeners: [NWListener] = []
    var peers: [Peer] = []
    var selected: Set<SessionChannel> = []
    var pendingEvidence: Set<HandshakeEvidence> = []
    var readyListeners = 0
    var complete = false
    var success = false
    var requestCount = 0
    var dataStarted = false
    var pullObserved = false

    init(ports: [UInt16]) { self.ports = ports }

    func run() -> Bool {
        queue.async { self.start() }
        if done.wait(timeout: .now() + 12) == .timedOut {
            queue.sync { self.finish(false, reason: "timeout") }
        }
        return queue.sync { success }
    }

    func start() {
        state.begin()
        do {
            for index in 1...3 {
                guard let port = NWEndpoint.Port(rawValue: ports[index]) else { throw ProtocolError.invalidPayload }
                let parameters = NWParameters.tcp
                parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: port)
                let listener = try NWListener(using: parameters)
                listener.stateUpdateHandler = { status in
                    switch status {
                    case .ready:
                        self.readyListeners += 1
                        if self.readyListeners == 3 { self.wake() }
                    case .failed: self.finish(false, reason: "listenerFailed")
                    default: break
                    }
                }
                listener.newConnectionHandler = { connection in
                    guard !self.complete, self.peers.filter({ !$0.isWake }).count < 4,
                          case .hostPort(let host, _) = connection.endpoint, host == .ipv4(.loopback) else {
                        connection.cancel(); return
                    }
                    do {
                        let channel: SessionChannel? = index == 2 ? .mediaControl : (index == 3 ? .mediaData : nil)
                        if let channel {
                            guard self.selected.insert(channel).inserted else { throw ProtocolError.wrongChannel }
                        }
                        let peer = try Peer(connection: connection, format: index == 1 ? .pxc : .media, channel: channel)
                        self.attach(peer)
                    } catch { connection.cancel(); self.finish(false, reason: "callbackRejected") }
                }
                listeners.append(listener); listener.start(queue: queue)
            }
        } catch { finish(false, reason: "listenerFailed") }
    }

    func wake() {
        guard !complete, let port = NWEndpoint.Port(rawValue: ports[0]) else { return }
        do {
            let connection = NWConnection(host: .ipv4(.loopback), port: port, using: .tcp)
            let peer = try Peer(connection: connection, format: .pxc, isWake: true)
            peers.append(peer)
            connection.stateUpdateHandler = { status in
                guard !self.complete else { return }
                if case .ready = status, !peer.started {
                    peer.started = true
                    do {
                        let frame = PXCFrame(command: 0x70000010, body: Data("{\"phoneType\":\"Android\",\"packageName\":\"com.cfmoto.cfmotointernational\"}".utf8))
                        try self.send([frame.encoded()], to: peer)
                        self.receive(peer)
                    } catch { self.finish(false, reason: "wakeEncodingFailed") }
                } else if case .failed = status { self.finish(false, reason: "dashUnreachable") }
            }
            connection.start(queue: queue)
        } catch { finish(false, reason: "wakeFailed") }
    }

    func attach(_ peer: Peer) {
        peers.append(peer)
        peer.connection.stateUpdateHandler = { status in
            guard !self.complete else { return }
            if case .ready = status, !peer.started {
                peer.started = true
                do {
                    if let channel = peer.channel {
                        try self.record(channel == .mediaControl ? .mediaControl : .mediaData)
                    }
                    self.receive(peer)
                } catch { self.finish(false, reason: "callbackRejected") }
            }
            else if case .failed = status { self.finish(false, reason: "connectionLost") }
        }
        peer.connection.start(queue: queue)
    }

    func receive(_ peer: Peer) {
        guard !complete else { return }
        peer.connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, eof, error in
            guard !self.complete else { return }
            do {
                if let data {
                    for frame in try peer.decoder.append(data) {
                        guard !self.complete else { break }
                        try self.handle(frame, from: peer)
                    }
                }
                if self.complete { return }
                if error != nil { self.finish(false, reason: "connectionLost"); return }
                if eof {
                    try peer.decoder.finish()
                    if !peer.isWake { self.finish(false, reason: "callbackClosed") }
                    return
                }
                self.finishIfDrained()
                self.receive(peer)
            } catch WriteQueueError.capacityExceeded { self.finish(false, reason: "writeQueueFull") }
            catch { self.finish(false, reason: "protocolViolation") }
        }
    }

    func handle(_ frame: WireFrame, from peer: Peer) throws {
        requestCount += 1
        if peer.isWake {
            guard case .pxc(let wake) = frame else { throw ProtocolError.wrongChannel }
            guard try Negotiator.wakeAccepted(wake) else {
                state.fail(.wakeRejected, generation: state.generation)
                finish(false, reason: "wakeRejected"); return
            }
            try state.acceptWake(generation: state.generation)
            for evidence in pendingEvidence { try state.record(evidence, generation: state.generation) }
            pendingEvidence.removeAll()
            return
        }
        if peer.channel == nil {
            guard case .pxc(let pxc) = frame else { throw ProtocolError.wrongChannel }
            let channel: SessionChannel
            switch pxc.command {
            case 0x10000: channel = .pxcControl
            case 0x20000: channel = .pxcData
            default: throw ProtocolError.wrongChannel
            }
            guard selected.insert(channel).inserted else { throw ProtocolError.wrongChannel }
            peer.channel = channel
        }
        guard let channel = peer.channel else { throw ProtocolError.wrongChannel }
        let result = try negotiator.handle(frame, on: channel)
        if result.requestsKeyframe {
            guard state.state == .ready else { throw SessionTransitionError.invalidTransition }
            dataStarted = true
        }
        try send(result.replies.map { try $0.encoded() }, to: peer)
        for evidence in result.evidence { try record(evidence) }
        if result.requestsFrame {
            guard state.state == .ready, dataStarted else { throw SessionTransitionError.invalidTransition }
            pullObserved = true
        }
    }

    func record(_ evidence: HandshakeEvidence) throws {
        if state.state == .connecting { pendingEvidence.insert(evidence) }
        else { try state.record(evidence, generation: state.generation) }
    }

    func send(_ batch: [Data], to peer: Peer) throws {
        try peer.writer.enqueue(batch)
        drainWrites(peer)
    }

    func drainWrites(_ peer: Peer) {
        guard !complete, let bytes = peer.writer.next() else { return }
        peer.connection.send(content: bytes, completion: .contentProcessed { error in
            guard !self.complete else { return }
            guard error == nil else { self.finish(false, reason: "sendFailed"); return }
            do { try peer.writer.completeWrite() }
            catch { self.finish(false, reason: "writerFailed"); return }
            self.drainWrites(peer)
            self.finishIfDrained()
        })
    }

    func finishIfDrained() {
        guard pullObserved, peers.allSatisfy({ $0.writer.pendingWriteCount == 0 && $0.decoder.bufferedByteCount == 0 }) else { return }
        finish(true, reason: "synthetic-handshake-and-empty-pull")
    }

    func finish(_ success: Bool, reason: String) {
        guard !complete else { return }
        complete = true; self.success = success
        let summary: [String: Any] = ["result": success ? "PASS" : "FAIL", "mode": "synthetic-no-crypto",
                                      "requests": requestCount, "reason": reason]
        if let bytes = try? JSONSerialization.data(withJSONObject: summary, options: [.sortedKeys]) {
            print(String(decoding: bytes, as: UTF8.self))
        }
        state.stop()
        selected.removeAll(); pendingEvidence.removeAll(); dataStarted = false; pullObserved = false
        for listener in listeners {
            listener.stateUpdateHandler = nil; listener.newConnectionHandler = nil; listener.cancel()
        }
        for peer in peers {
            peer.writer.close(); peer.connection.stateUpdateHandler = nil; peer.connection.cancel()
        }
        listeners.removeAll(); peers.removeAll()
        done.signal()
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
let portArguments = arguments.isEmpty ? ["10930", "10922", "10921", "10920"] : arguments
let ports = portArguments.compactMap(UInt16.init)
guard ports.count == 4, ports.allSatisfy({ $0 > 0 }), Set(ports).count == 4 else {
    print("Usage: ProtocolProbe [wake-port pxc-port media-control-port media-data-port]")
    exit(2)
}
exit(HostProbe(ports: ports).run() ? 0 : 1)
