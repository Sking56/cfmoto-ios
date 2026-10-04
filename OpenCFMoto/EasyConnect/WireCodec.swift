import Foundation

public enum ProtocolError: Error, Equatable, Sendable {
    case invalidLength, badChecksum, frameTooLarge, truncatedFrame, streamTerminated
    case invalidPayload, unsupportedCommand, wrongChannel, identityUnavailable, unsupportedCapture
}

public enum WireFormat: String, Sendable {
    case pxc, media, rawVideo = "raw-video"

    var headerSize: Int {
        switch self { case .pxc: 16; case .media: 8; case .rawVideo: 4 }
    }
    var defaultLimit: Int {
        switch self { case .pxc: 1_048_576; case .media: 65_543; case .rawVideo: 1_048_580 }
    }
}

extension Data {
    func littleUInt16(at offset: Int) -> UInt16 {
        UInt16(self[startIndex + offset]) | UInt16(self[startIndex + offset + 1]) << 8
    }

    func littleUInt32(at offset: Int) -> UInt32 {
        (0..<4).reduce(0) { $0 | UInt32(self[startIndex + offset + $1]) << ($1 * 8) }
    }

    mutating func appendLittle(_ value: UInt16) {
        append(contentsOf: [UInt8(truncatingIfNeeded: value), UInt8(truncatingIfNeeded: value >> 8)])
    }

    mutating func appendLittle(_ value: UInt32) {
        append(contentsOf: (0..<4).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) })
    }
}

public struct PXCFrame: Equatable, Sendable {
    public let command: UInt32
    public let body: Data
    public let reserved: UInt32

    public init(command: UInt32, body: Data = Data(), reserved: UInt32 = 0) {
        self.command = command; self.body = body; self.reserved = reserved
    }

    public func encoded(maximumBytes: Int = 1_048_576) throws -> Data {
        guard maximumBytes >= 16, body.count <= maximumBytes - 16,
              body.count <= Int(UInt32.max) - 16 else { throw ProtocolError.frameTooLarge }
        let total = UInt32(16 + body.count)
        var bytes = Data()
        bytes.appendLittle(command); bytes.appendLittle(total)
        bytes.appendLittle(command ^ total); bytes.appendLittle(reserved)
        bytes.append(body)
        return bytes
    }
}

public struct MediaFrame: Equatable, Sendable {
    public let command: Int16
    public let body: Data
    public let token: Int32

    public init(command: Int16, body: Data = Data(), token: Int32 = 0) {
        self.command = command; self.body = body; self.token = token
    }

    public func encoded() throws -> Data {
        guard body.count <= Int(UInt16.max) else { throw ProtocolError.frameTooLarge }
        var bytes = Data()
        bytes.appendLittle(UInt16(bitPattern: command)); bytes.appendLittle(UInt16(body.count))
        bytes.appendLittle(UInt32(bitPattern: token)); bytes.append(body)
        return bytes
    }
}

public enum WireFrame: Equatable, Sendable {
    case pxc(PXCFrame), media(MediaFrame), rawVideo(Data)

    public func encoded() throws -> Data {
        switch self {
        case .pxc(let frame): return try frame.encoded()
        case .media(let frame): return try frame.encoded()
        case .rawVideo(let body):
            guard !body.isEmpty else { throw ProtocolError.invalidLength }
            guard body.count <= 1_048_576 else { throw ProtocolError.frameTooLarge }
            var bytes = Data(); bytes.appendLittle(UInt32(body.count)); bytes.append(body)
            return bytes
        }
    }
}

public struct StreamDecoder: Sendable {
    public let format: WireFormat
    public let maximumFrameBytes: Int
    public private(set) var bufferedByteCount = 0
    private var buffer = Data()
    private var targetSize: Int?
    private var terminated = false

    public init(format: WireFormat, maximumFrameBytes: Int? = nil) throws {
        let limit = maximumFrameBytes ?? format.defaultLimit
        guard limit >= format.headerSize else { throw ProtocolError.invalidLength }
        self.format = format; self.maximumFrameBytes = limit
    }

    public mutating func append(_ input: Data) throws -> [WireFrame] {
        guard !terminated else { throw ProtocolError.streamTerminated }
        var frames: [WireFrame] = []
        var offset = input.startIndex
        do {
            // Retain at most one bounded frame, even when a read coalesces many frames.
            while offset < input.endIndex {
                let target = targetSize ?? format.headerSize
                let count = min(target - buffer.count, input.endIndex - offset)
                buffer.append(input[offset..<(offset + count)])
                offset += count
                bufferedByteCount = buffer.count
                if targetSize == nil, buffer.count == format.headerSize {
                    targetSize = try validatedSize()
                }
                if let size = targetSize, buffer.count == size {
                    frames.append(decodedFrame())
                    buffer.removeAll(keepingCapacity: true)
                    bufferedByteCount = 0; targetSize = nil
                }
            }
            return frames
        } catch {
            terminated = true; buffer = Data(); bufferedByteCount = 0
            throw error
        }
    }

    public mutating func finish() throws {
        guard !terminated else { throw ProtocolError.streamTerminated }
        terminated = true
        guard buffer.isEmpty else {
            buffer = Data(); bufferedByteCount = 0
            throw ProtocolError.truncatedFrame
        }
    }

    private func validatedSize() throws -> Int {
        let size: Int
        switch format {
        case .pxc:
            let command = buffer.littleUInt32(at: 0), total = buffer.littleUInt32(at: 4)
            guard command ^ total == buffer.littleUInt32(at: 8) else { throw ProtocolError.badChecksum }
            guard total >= 16 else { throw ProtocolError.invalidLength }
            size = Int(total)
        case .media: size = 8 + Int(buffer.littleUInt16(at: 2))
        case .rawVideo:
            let length = buffer.littleUInt32(at: 0)
            guard length > 0 else { throw ProtocolError.invalidLength }
            size = 4 + Int(length)
        }
        guard size <= maximumFrameBytes else { throw ProtocolError.frameTooLarge }
        return size
    }

    private func decodedFrame() -> WireFrame {
        let body = Data(buffer.dropFirst(format.headerSize))
        switch format {
        case .pxc: return .pxc(PXCFrame(command: buffer.littleUInt32(at: 0), body: body,
                                       reserved: buffer.littleUInt32(at: 12)))
        case .media: return .media(MediaFrame(command: Int16(bitPattern: buffer.littleUInt16(at: 0)),
                                             body: body, token: Int32(bitPattern: buffer.littleUInt32(at: 4))))
        case .rawVideo: return .rawVideo(body)
        }
    }
}
