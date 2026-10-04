import CoreMedia
import CoreVideo
import Foundation
import VideoToolbox

enum InspectionError: Error { case malformed, oversized, framework(Int32), missingImage }

struct ImageInspection: Codable, Sendable {
    let width: Int
    let height: Int
    let colors: [[Int]]
    let markerX: Int
}

final class DecodedResult: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Result<ImageInspection, InspectionError>?
    func set(_ result: Result<ImageInspection, InspectionError>) { lock.lock(); defer { lock.unlock() }; value = result }
    func get() -> Result<ImageInspection, InspectionError>? { lock.lock(); defer { lock.unlock() }; return value }
}

func check(_ status: OSStatus) throws { if status != noErr { throw InspectionError.framework(status) } }

// Independent receiver parser: no encoder, protocol-core or fixture imports.
func splitNALs(_ bytes: [UInt8]) throws -> [[UInt8]] {
    func prefix(_ index: Int) -> Int {
        if index + 4 <= bytes.count, Array(bytes[index..<(index + 4)]) == [0, 0, 0, 1] { return 4 }
        if index + 3 <= bytes.count, Array(bytes[index..<(index + 3)]) == [0, 0, 1] { return 3 }
        return 0
    }
    var offset = 0, nals: [[UInt8]] = []
    while offset < bytes.count {
        let header = prefix(offset)
        guard header > 0 else { throw InspectionError.malformed }
        let start = offset + header
        offset = start
        while offset < bytes.count, prefix(offset) == 0 { offset += 1 }
        guard offset > start else { throw InspectionError.malformed }
        let nal = Array(bytes[start..<offset])
        guard nal[0] & 0x80 == 0, (1...23).contains(nal[0] & 31) else { throw InspectionError.malformed }
        nals.append(nal)
    }
    guard !nals.isEmpty else { throw InspectionError.malformed }
    return nals
}

func inspect(_ buffer: CVPixelBuffer) throws -> ImageInspection {
    let width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer)
    guard width >= 16, height >= 16, width <= 1920, height <= 1080,
          CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA else { throw InspectionError.malformed }
    try check(CVPixelBufferLockBaseAddress(buffer, .readOnly))
    defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
    guard let base = CVPixelBufferGetBaseAddress(buffer) else { throw InspectionError.missingImage }
    let stride = CVPixelBufferGetBytesPerRow(buffer)
    func rgb(_ x: Int, _ y: Int) -> [Int] {
        let pixel = base.advanced(by: y * stride + x * 4).assumingMemoryBound(to: UInt8.self)
        return [Int(pixel[2]), Int(pixel[1]), Int(pixel[0])]
    }
    let colors = [rgb(width / 6, height / 3), rgb(width / 2, height / 3), rgb(width * 5 / 6, height / 3)]
    let markerX = (0..<width).first { rgb($0, height * 7 / 8).allSatisfy { $0 > 190 } } ?? -1
    return ImageInspection(width: width, height: height, colors: colors, markerX: markerX)
}

final class ReceiverDecoder {
    var session: VTDecompressionSession?
    var format: CMVideoFormatDescription?
    var sps: [UInt8] = [], pps: [UInt8] = []
    var keyframes = 0
    var profile = 0, level = 0

    func decode(_ bytes: [UInt8], sequence: Int) throws -> ImageInspection {
        let nals = try splitNALs(bytes)
        let nextSPS = nals.first { $0[0] & 31 == 7 }
        let nextPPS = nals.first { $0[0] & 31 == 8 }
        let keyframe = nals.contains { $0[0] & 31 == 5 }
        if keyframe {
            guard let nextSPS, let nextPPS, nextSPS.count >= 4 else { throw InspectionError.malformed }
            keyframes += 1; profile = Int(nextSPS[1]); level = Int(nextSPS[3])
            if session == nil || nextSPS != sps || nextPPS != pps {
                if let session { VTDecompressionSessionInvalidate(session) }
                session = nil; sps = nextSPS; pps = nextPPS
                var description: CMVideoFormatDescription?
                let status = sps.withUnsafeBufferPointer { first in
                    pps.withUnsafeBufferPointer { second in
                        let pointers = [first.baseAddress!, second.baseAddress!]
                        let sizes = [first.count, second.count]
                        return CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                            parameterSetCount: 2, parameterSetPointers: pointers, parameterSetSizes: sizes,
                            nalUnitHeaderLength: 4, formatDescriptionOut: &description)
                    }
                }
                try check(status)
                guard let description else { throw InspectionError.malformed }
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                guard (16...1920).contains(dimensions.width), (16...1080).contains(dimensions.height) else { throw InspectionError.oversized }
                format = description
                let attributes = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as CFDictionary
                try check(VTDecompressionSessionCreate(allocator: kCFAllocatorDefault, formatDescription: description,
                    decoderSpecification: nil, imageBufferAttributes: attributes, outputCallback: nil,
                    decompressionSessionOut: &session))
            }
        }
        guard let session, let format else { throw InspectionError.malformed }
        var avcc = Data()
        for nal in nals where ![7, 8].contains(nal[0] & 31) {
            let length = UInt32(nal.count)
            avcc.append(contentsOf: [UInt8(truncatingIfNeeded: length >> 24), UInt8(truncatingIfNeeded: length >> 16),
                                    UInt8(truncatingIfNeeded: length >> 8), UInt8(truncatingIfNeeded: length)])
            avcc.append(contentsOf: nal)
        }
        guard !avcc.isEmpty else { throw InspectionError.malformed }
        var block: CMBlockBuffer?
        try check(CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: avcc.count,
            blockAllocator: kCFAllocatorDefault, customBlockSource: nil, offsetToData: 0, dataLength: avcc.count,
            flags: 0, blockBufferOut: &block))
        guard let block else { throw InspectionError.malformed }
        try check(avcc.withUnsafeBytes { CMBlockBufferReplaceDataBytes(with: $0.baseAddress!, blockBuffer: block, offsetIntoDestination: 0, dataLength: avcc.count) })
        var sample: CMSampleBuffer?
        var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 30),
                                       presentationTimeStamp: CMTime(value: Int64(sequence), timescale: 30), decodeTimeStamp: .invalid)
        var size = avcc.count
        try check(CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: block, formatDescription: format,
            sampleCount: 1, sampleTimingEntryCount: 1, sampleTimingArray: &timing, sampleSizeEntryCount: 1,
            sampleSizeArray: &size, sampleBufferOut: &sample))
        guard let sample else { throw InspectionError.malformed }
        let result = DecodedResult()
        try check(VTDecompressionSessionDecodeFrame(session, sampleBuffer: sample, flags: [], infoFlagsOut: nil) { status, _, image, _, _ in
            guard status == noErr else { result.set(.failure(.framework(status))); return }
            guard let image else { result.set(.failure(.missingImage)); return }
            do { result.set(.success(try inspect(image))) }
            catch let error as InspectionError { result.set(.failure(error)) }
            catch { result.set(.failure(.malformed)) }
        })
        try check(VTDecompressionSessionWaitForAsynchronousFrames(session))
        guard let output = result.get() else { throw InspectionError.missingImage }
        return try output.get()
    }

    deinit { if let session { VTDecompressionSessionInvalidate(session) } }
}

do {
    var input = Data()
    while let chunk = try FileHandle.standardInput.read(upToCount: 65_536), !chunk.isEmpty {
        guard chunk.count <= 16_777_216 - input.count else { throw InspectionError.oversized }
        input.append(chunk)
    }
    let decoder = ReceiverDecoder()
    var offset = 0, images: [ImageInspection] = []
    while offset < input.count {
        guard input.count - offset >= 4, images.count < 120 else { throw InspectionError.malformed }
        let length = (0..<4).reduce(0) { $0 | Int(input[offset + $1]) << (8 * $1) }
        offset += 4
        guard length > 0, length <= 1_048_576, length <= input.count - offset else { throw InspectionError.malformed }
        images.append(try decoder.decode(Array(input[offset..<(offset + length)]), sequence: images.count))
        offset += length
    }
    guard !images.isEmpty else { throw InspectionError.malformed }
    struct Summary: Encodable { let result = "PASS"; let images: [ImageInspection]; let keyframes: Int; let profile: Int; let level: Int }
    let output = try JSONEncoder().encode(Summary(images: images, keyframes: decoder.keyframes, profile: decoder.profile, level: decoder.level))
    print(String(decoding: output, as: UTF8.self))
} catch {
    print("INSPECTOR FAIL: malformed or undecodable synthetic video")
    exit(1)
}
