import Foundation

public enum FrameAdmission: Equatable, Sendable { case accepted, ignored, needsKeyframe }

public struct FrameQueue: Sendable {
    public let maximumFrames: Int
    public let maximumBytes: Int
    public private(set) var generation: UInt64 = 0
    public private(set) var bufferedByteCount = 0
    public private(set) var waitingForKeyframe = true
    public var count: Int { frames.count }
    private var active = false
    private var frames: [EncodedAccessUnit] = []

    public init(maximumFrames: Int = 3, maximumBytes: Int = 1_048_576) throws {
        guard maximumFrames > 0, maximumBytes > 0 else { throw VideoError.invalidConfiguration }
        self.maximumFrames = maximumFrames; self.maximumBytes = maximumBytes
    }

    public mutating func start(generation: UInt64) {
        self.generation = generation; active = true
        invalidateChain()
    }

    public mutating func invalidateChain() {
        frames.removeAll(); bufferedByteCount = 0; waitingForKeyframe = true
    }

    public mutating func admit(_ unit: EncodedAccessUnit) -> FrameAdmission {
        guard active, unit.generation == generation else { return .ignored }
        guard !unit.bytes.isEmpty, unit.bytes.count <= min(maximumBytes, 1_048_576) else {
            invalidateChain(); return .needsKeyframe
        }
        if frames.count == maximumFrames || unit.bytes.count > maximumBytes - bufferedByteCount { invalidateChain() }
        guard !waitingForKeyframe || unit.isKeyframe else { return .needsKeyframe }
        frames.append(unit); bufferedByteCount += unit.bytes.count; waitingForKeyframe = false
        return .accepted
    }

    public mutating func pull() -> EncodedAccessUnit? {
        guard active, !frames.isEmpty else { return nil }
        let first = frames.removeFirst(); bufferedByteCount -= first.bytes.count
        return first
    }

    public mutating func stop() {
        active = false; generation &+= 1; invalidateChain()
    }
}
