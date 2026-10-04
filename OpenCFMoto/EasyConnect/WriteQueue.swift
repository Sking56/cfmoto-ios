import Foundation

public enum WriteQueueError: Error, Equatable, Sendable {
    case invalidLimits, emptyWrite, capacityExceeded, noWriteInFlight, closed
}

// The in-flight write retains its capacity until the transport confirms completion.
public struct WriteQueue: Sendable {
    public let maximumWrites: Int
    public let maximumBytes: Int
    public private(set) var bufferedByteCount = 0
    public private(set) var isWriting = false
    public var pendingWriteCount: Int { writes.count }
    private var writes: [Data] = []
    private var closed = false

    public init(maximumWrites: Int = 64, maximumBytes: Int = 262_144) throws {
        guard maximumWrites > 0, maximumBytes > 0 else { throw WriteQueueError.invalidLimits }
        self.maximumWrites = maximumWrites; self.maximumBytes = maximumBytes
    }

    public mutating func enqueue(_ batch: [Data]) throws {
        guard !closed else { throw WriteQueueError.closed }
        guard batch.count <= maximumWrites - writes.count else { throw WriteQueueError.capacityExceeded }
        var total = bufferedByteCount
        for bytes in batch {
            guard !bytes.isEmpty else { throw WriteQueueError.emptyWrite }
            guard bytes.count <= maximumBytes - total else { throw WriteQueueError.capacityExceeded }
            total += bytes.count
        }
        // Admit a multi-reply exchange atomically; never retain only its first reply.
        writes.append(contentsOf: batch)
        bufferedByteCount = total
    }

    public mutating func next() -> Data? {
        guard !closed, !isWriting, let first = writes.first else { return nil }
        isWriting = true
        return first
    }

    public mutating func completeWrite() throws {
        guard !closed else { throw WriteQueueError.closed }
        guard isWriting else { throw WriteQueueError.noWriteInFlight }
        bufferedByteCount -= writes.removeFirst().count
        isWriting = false
    }

    public mutating func close() {
        closed = true; isWriting = false; bufferedByteCount = 0
        writes.removeAll()
    }
}
