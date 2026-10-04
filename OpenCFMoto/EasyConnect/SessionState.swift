public enum SessionState: Equatable, Sendable {
    case idle, connecting, negotiating, ready, failed(SessionFailure)
}

public enum SessionFailure: Equatable, Sendable {
    case wakeRejected, protocolViolation, identityUnavailable, connectionLost, timeout
}

public enum HandshakeEvidence: CaseIterable, Hashable, Sendable {
    case pxcControl, pxcData, identity, checkSN, mediaControl, mediaData, captureConfiguration, version, h264
}

public enum SessionTransitionError: Error, Equatable {
    case invalidTransition
}

public struct SessionStateMachine: Sendable {
    public private(set) var state: SessionState = .idle
    public private(set) var generation: UInt64 = 0
    public private(set) var evidence: Set<HandshakeEvidence> = []

    public init() {}

    @discardableResult public mutating func begin() -> UInt64 {
        generation &+= 1; evidence.removeAll(); state = .connecting
        return generation
    }

    public mutating func acceptWake(generation: UInt64) throws {
        guard generation == self.generation else { return }
        guard state == .connecting else { throw SessionTransitionError.invalidTransition }
        state = .negotiating
    }

    public mutating func record(_ item: HandshakeEvidence, generation: UInt64) throws {
        guard generation == self.generation else { return }
        guard state == .negotiating || state == .ready else { throw SessionTransitionError.invalidTransition }
        evidence.insert(item)
        if evidence.count == HandshakeEvidence.allCases.count { state = .ready }
    }

    public mutating func fail(_ reason: SessionFailure, generation: UInt64) {
        guard generation == self.generation,
              state == .connecting || state == .negotiating || state == .ready else { return }
        evidence.removeAll(); state = .failed(reason)
    }

    public mutating func stop() {
        generation &+= 1; evidence.removeAll(); state = .idle
    }
}
