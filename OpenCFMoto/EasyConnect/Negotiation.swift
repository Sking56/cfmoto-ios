import Foundation

public enum SessionChannel: Hashable, Sendable {
    case pxcControl, pxcData, mediaControl, mediaData
}

public protocol ClientIdentityProvider: Sendable {
    func reply(toHUID huid: String) throws -> Data
}

public struct CaptureConfiguration: Equatable, Sendable {
    public let width: UInt16
    public let height: UInt16
    public let framesPerSecond: Int32
    public let encoder: Int32
    public let extensionFlag: UInt8

    public init(body: Data) throws {
        guard body.count >= 30 else { throw ProtocolError.invalidPayload }
        let width = body.littleUInt16(at: 0) & 0xfff0
        let height = body.littleUInt16(at: 2) & 0xfff0
        let fps = Int32(bitPattern: body.littleUInt32(at: 4))
        let requestedEncoder = Int32(bitPattern: body.littleUInt32(at: 8))
        let encoder: Int32 = requestedEncoder == 0 ? 2 : requestedEncoder
        guard width > 0, height > 0, width <= 4096, height <= 4096,
              (1...60).contains(fps), encoder == 2 else { throw ProtocolError.unsupportedCapture }
        self.width = width; self.height = height; self.framesPerSecond = fps
        self.encoder = encoder; self.extensionFlag = body[body.startIndex + 29]
    }

    public var replyBody: Data {
        var bytes = Data(); bytes.appendLittle(UInt32(bitPattern: encoder))
        bytes.appendLittle(width); bytes.appendLittle(height); bytes.append(extensionFlag)
        return bytes
    }
}

public struct NegotiationResult: Sendable {
    public let replies: [WireFrame]
    public let evidence: [HandshakeEvidence]
    public let capture: CaptureConfiguration?
    public let requestsKeyframe: Bool
    public let requestsFrame: Bool
}

public struct Negotiator: Sendable {
    private let identity: (any ClientIdentityProvider)?

    public init(identity: (any ClientIdentityProvider)? = nil) { self.identity = identity }

    public static func wakeAccepted(_ frame: PXCFrame) throws -> Bool {
        guard frame.command == 0x70000011 else { throw ProtocolError.unsupportedCommand }
        struct Reply: Decodable { let status: Bool }
        guard let reply = try? JSONDecoder().decode(Reply.self, from: frame.body) else {
            throw ProtocolError.invalidPayload
        }
        return reply.status
    }

    public func handle(_ frame: WireFrame, on channel: SessionChannel) throws -> NegotiationResult {
        var evidence: [HandshakeEvidence] = []
        var replies: [WireFrame] = []
        var capture: CaptureConfiguration?
        var keyframe = false, pull = false
        switch (channel, frame) {
        case (.pxcControl, .pxc(let request)), (.pxcData, .pxc(let request)):
            switch request.command {
            case 0x10000 where channel == .pxcControl:
                try requireEmpty(request.body); replies = [.pxc(PXCFrame(command: 0x10001))]; evidence = [.pxcControl]
            case 0x20000 where channel == .pxcData:
                try requireEmpty(request.body); replies = [.pxc(PXCFrame(command: 0x20001))]; evidence = [.pxcData]
            case 0x10010:
                struct Request: Decodable { let HUID: String }
                guard let value = try? JSONDecoder().decode(Request.self, from: request.body),
                      !value.HUID.isEmpty, value.HUID.utf8.count <= 1024 else { throw ProtocolError.invalidPayload }
                guard let identity else { throw ProtocolError.identityUnavailable }
                let body = try identity.reply(toHUID: value.HUID)
                guard body.count <= 65_535,
                      (try? JSONSerialization.jsonObject(with: body)) is [String: Any] else {
                    throw ProtocolError.invalidPayload
                }
                replies = [.pxc(PXCFrame(command: 0x10011, body: body))]; evidence = [.identity]
            case 0x10690:
                try requireEmpty(request.body); replies = [.pxc(PXCFrame(command: 0x10691))]
            case 0x103e0:
                struct Request: Decodable { let sn: String }
                struct Reply: Encodable {
                    let isOk = true, errCode = 0, errMsg = ""
                    let id: String
                    let client_set = "easy_conn"
                }
                guard let value = try? JSONDecoder().decode(Request.self, from: request.body),
                      !value.sn.isEmpty, value.sn.utf8.count <= 1024 else { throw ProtocolError.invalidPayload }
                let body = try JSONEncoder().encode(Reply(id: value.sn))
                replies = [.pxc(PXCFrame(command: 0x103e1)), .pxc(PXCFrame(command: 0x201c0, body: body))]
                evidence = [.checkSN]
            case 0x201c1:
                try requireEmpty(request.body)
            case 0x70000000:
                try requireEmpty(request.body); replies = [.pxc(PXCFrame(command: 0x70000001))]
            case 0x70000001:
                try requireEmpty(request.body)
            default: throw ProtocolError.unsupportedCommand
            }
        case (.mediaControl, .media(let request)):
            let command: Int16
            var body = Data()
            switch request.command {
            case 16:
                let configuration = try CaptureConfiguration(body: request.body)
                capture = configuration
                body = configuration.replyBody; command = 17; evidence = [.captureConfiguration]
            case 48:
                try requireEmpty(request.body); body.appendLittle(UInt32(3)); body.appendLittle(UInt32(1))
                command = 49; evidence = [.version]
            case 64: try requireEmpty(request.body); command = 65
            case 96:
                guard (try? JSONSerialization.jsonObject(with: request.body)) is [String: Any] else {
                    throw ProtocolError.invalidPayload
                }
                body = Data("{\"state\":0}".utf8); command = 97
            case 128: try requireEmpty(request.body); command = 129; evidence = [.h264]
            default: throw ProtocolError.unsupportedCommand
            }
            replies = [.media(MediaFrame(command: command, body: body))]
        case (.mediaData, .media(let request)):
            try requireEmpty(request.body)
            switch request.command {
            case 112: replies = [.media(MediaFrame(command: 113))]; keyframe = true
            case 114: pull = true
            default: throw ProtocolError.unsupportedCommand
            }
        default: throw ProtocolError.wrongChannel
        }
        return NegotiationResult(replies: replies, evidence: evidence, capture: capture,
                                 requestsKeyframe: keyframe, requestsFrame: pull)
    }

    private func requireEmpty(_ body: Data) throws {
        guard body.isEmpty else { throw ProtocolError.invalidPayload }
    }
}
