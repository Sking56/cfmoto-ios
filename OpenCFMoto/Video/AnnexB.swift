import Foundation

public enum VideoError: Error, Equatable, Sendable {
    case invalidConfiguration, invalidFrame, invalidNAL, frameTooLarge, missingOutput
    case frameworkFailure(Int32)
}

public struct EncodedAccessUnit: Equatable, Sendable {
    public let bytes: Data
    public let isKeyframe: Bool
    public let sequence: UInt64
    public let generation: UInt64

    public init(bytes: Data, isKeyframe: Bool, sequence: UInt64, generation: UInt64) {
        self.bytes = bytes; self.isKeyframe = isKeyframe
        self.sequence = sequence; self.generation = generation
    }
}

public enum AnnexB {
    public static func accessUnit(lengthPrefixed: Data, lengthBytes: Int, parameterSets: [Data],
                                  sequence: UInt64, generation: UInt64) throws -> EncodedAccessUnit {
        guard [1, 2, 4].contains(lengthBytes), !lengthPrefixed.isEmpty else { throw VideoError.invalidNAL }
        guard lengthPrefixed.count <= 1_048_576 else { throw VideoError.frameTooLarge }
        var offset = lengthPrefixed.startIndex
        var nals: [Data] = []
        while offset < lengthPrefixed.endIndex {
            guard lengthPrefixed.endIndex - offset >= lengthBytes else { throw VideoError.invalidNAL }
            var size = 0
            for byte in lengthPrefixed[offset..<(offset + lengthBytes)] { size = size << 8 | Int(byte) }
            offset += lengthBytes
            guard size > 0, size <= lengthPrefixed.endIndex - offset else { throw VideoError.invalidNAL }
            let nal = Data(lengthPrefixed[offset..<(offset + size)])
            guard let first = nal.first, first & 0x80 == 0, (1...23).contains(first & 0x1f) else { throw VideoError.invalidNAL }
            nals.append(nal); offset += size
        }
        let keyframe = nals.contains { $0.first.map { $0 & 0x1f == 5 } == true }
        if keyframe {
            guard parameterSets.contains(where: { $0.first.map { $0 & 0x1f == 7 } == true }),
                  parameterSets.contains(where: { $0.first.map { $0 & 0x1f == 8 } == true }) else { throw VideoError.invalidNAL }
        }
        var output = Data()
        for nal in (keyframe ? parameterSets : []) + nals {
            guard !nal.isEmpty, nal.count <= 1_048_576 - output.count - 4 else { throw VideoError.frameTooLarge }
            output.append(contentsOf: [0, 0, 0, 1]); output.append(nal)
        }
        return EncodedAccessUnit(bytes: output, isKeyframe: keyframe, sequence: sequence, generation: generation)
    }
}
