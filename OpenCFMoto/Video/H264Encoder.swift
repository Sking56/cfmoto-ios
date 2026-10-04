import CoreMedia
import CoreVideo
import Foundation
import VideoToolbox

private final class CompressionResult: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<EncodedAccessUnit, VideoError>?

    func set(_ value: Result<EncodedAccessUnit, VideoError>) { lock.lock(); defer { lock.unlock() }; result = value }
    func get() -> Result<EncodedAccessUnit, VideoError>? { lock.lock(); defer { lock.unlock() }; return result }
}

// Caller-owned serial encoder; the synthetic probe flushes one frame at a time.
public final class H264Encoder {
    typealias Submission = (VTCompressionSession, CVPixelBuffer, CMTime, CMTime, CFDictionary?, @escaping VTCompressionOutputHandler) -> OSStatus
    typealias Flush = (VTCompressionSession) -> OSStatus
    private var session: VTCompressionSession?
    private let width: Int
    private let height: Int
    private let fps: Int32
    private var lastSequence: UInt64?
    private let submit: Submission
    private let flush: Flush

    public convenience init(width: Int, height: Int, framesPerSecond: Int32) throws {
        try self.init(width: width, height: height, framesPerSecond: framesPerSecond,
                      submit: { session, buffer, time, duration, properties, output in
                          VTCompressionSessionEncodeFrame(session, imageBuffer: buffer, presentationTimeStamp: time,
                                                          duration: duration, frameProperties: properties, infoFlagsOut: nil,
                                                          outputHandler: output)
                      }, flush: { VTCompressionSessionCompleteFrames($0, untilPresentationTimeStamp: .invalid) })
    }

    init(width: Int, height: Int, framesPerSecond: Int32, submit: @escaping Submission, flush: @escaping Flush) throws {
        _ = try SyntheticFrameSource(width: width, height: height)
        guard (1...60).contains(framesPerSecond) else { throw VideoError.invalidConfiguration }
        self.width = width; self.height = height; self.fps = framesPerSecond
        self.submit = submit; self.flush = flush
        var created: VTCompressionSession?
        let attributes = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as CFDictionary
        try Self.check(VTCompressionSessionCreate(allocator: kCFAllocatorDefault, width: Int32(width), height: Int32(height),
                                                  codecType: kCMVideoCodecType_H264, encoderSpecification: nil,
                                                  imageBufferAttributes: attributes, compressedDataAllocator: nil,
                                                  outputCallback: nil, refcon: nil, compressionSessionOut: &created))
        guard let created else { throw VideoError.missingOutput }
        session = created
        do {
            for (key, value) in [(kVTCompressionPropertyKey_RealTime, kCFBooleanTrue as CFTypeRef),
                                 (kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse as CFTypeRef),
                                 (kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_3_1 as CFTypeRef),
                                 (kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: 2_500_000) as CFTypeRef),
                                 (kVTCompressionPropertyKey_ExpectedFrameRate, NSNumber(value: fps) as CFTypeRef),
                                 (kVTCompressionPropertyKey_MaxKeyFrameInterval, NSNumber(value: fps) as CFTypeRef),
                                 (kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, NSNumber(value: 1) as CFTypeRef)] {
                try Self.check(VTSessionSetProperty(created, key: key, value: value))
            }
            try Self.check(VTCompressionSessionPrepareToEncodeFrames(created))
        } catch { close(); throw error }
    }

    public func encode(_ buffer: CVPixelBuffer, sequence: UInt64, generation: UInt64, forceKeyframe: Bool) throws -> EncodedAccessUnit {
        guard let session, CVPixelBufferGetWidth(buffer) == width, CVPixelBufferGetHeight(buffer) == height,
              CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA, sequence <= UInt64(Int64.max),
              lastSequence.map({ sequence > $0 }) ?? true else { throw VideoError.invalidFrame }
        lastSequence = sequence
        let result = CompressionResult()
        let properties = forceKeyframe ? [kVTEncodeFrameOptionKey_ForceKeyFrame: true] as CFDictionary : nil
        do {
            let status = submit(session, buffer, CMTime(value: Int64(sequence), timescale: fps),
                                CMTime(value: 1, timescale: fps), properties) { status, flags, sample in
                guard status == noErr else { result.set(.failure(.frameworkFailure(status))); return }
                guard !flags.contains(.frameDropped), let sample else { result.set(.failure(.missingOutput)); return }
                do { result.set(.success(try Self.accessUnit(sample, sequence: sequence, generation: generation))) }
                catch let error as VideoError { result.set(.failure(error)) }
                catch { result.set(.failure(.invalidNAL)) }
            }
            try Self.check(status)
            try Self.check(flush(session))
            guard let output = result.get() else { throw VideoError.missingOutput }
            return try output.get()
        } catch {
            // Unknown completion or discarded output cannot feed another predictive frame.
            close()
            throw error
        }
    }

    private static func accessUnit(_ sample: CMSampleBuffer, sequence: UInt64, generation: UInt64) throws -> EncodedAccessUnit {
        guard CMSampleBufferDataIsReady(sample), let block = CMSampleBufferGetDataBuffer(sample),
              let format = CMSampleBufferGetFormatDescription(sample) else { throw VideoError.missingOutput }
        let size = CMBlockBufferGetDataLength(block)
        guard size > 0, size <= 1_048_576 else { throw VideoError.frameTooLarge }
        var bytes = Data(count: size)
        try check(bytes.withUnsafeMutableBytes { CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: size, destination: $0.baseAddress!) })
        var count = 0, lengthBytes: Int32 = 0
        try check(CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, parameterSetIndex: 0, parameterSetPointerOut: nil,
                                                                   parameterSetSizeOut: nil, parameterSetCountOut: &count,
                                                                   nalUnitHeaderLengthOut: &lengthBytes))
        guard (2...16).contains(count) else { throw VideoError.invalidNAL }
        var sets: [Data] = []
        for index in 0..<count {
            var pointer: UnsafePointer<UInt8>?, length = 0
            try check(CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, parameterSetIndex: index, parameterSetPointerOut: &pointer,
                                                                       parameterSetSizeOut: &length, parameterSetCountOut: nil,
                                                                       nalUnitHeaderLengthOut: nil))
            guard let pointer, length > 0, length <= 65_535 else { throw VideoError.invalidNAL }
            sets.append(Data(bytes: pointer, count: length))
        }
        return try AnnexB.accessUnit(lengthPrefixed: bytes, lengthBytes: Int(lengthBytes), parameterSets: sets,
                                     sequence: sequence, generation: generation)
    }

    private static func check(_ status: OSStatus) throws {
        guard status == noErr else { throw VideoError.frameworkFailure(status) }
    }

    public func close() { if let session { VTCompressionSessionInvalidate(session) }; session = nil }
    deinit { close() }
}
