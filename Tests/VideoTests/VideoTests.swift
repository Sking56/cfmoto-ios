import CoreVideo
import Foundation
import XCTest
import CoreMedia
import VideoToolbox
@testable import OpenCFMotoVideo

final class VideoTests: XCTestCase {
    private func unit(_ number: UInt64, keyframe: Bool = false, generation: UInt64 = 1, size: Int = 2) -> EncodedAccessUnit {
        EncodedAccessUnit(bytes: Data(repeating: UInt8(truncatingIfNeeded: number), count: size),
                          isKeyframe: keyframe, sequence: number, generation: generation)
    }

    func testAnnexBExactBytesAndIDRParameterSets() throws {
        let access = try AnnexB.accessUnit(lengthPrefixed: Data([0, 0, 0, 2, 0x65, 0xab]), lengthBytes: 4,
                                          parameterSets: [Data([0x67, 1]), Data([0x68, 2])], sequence: 0, generation: 7)
        XCTAssertEqual(access.bytes, Data([0, 0, 0, 1, 0x67, 1, 0, 0, 0, 1, 0x68, 2, 0, 0, 0, 1, 0x65, 0xab]))
        XCTAssertTrue(access.isKeyframe); XCTAssertEqual(access.generation, 7)
        for width in [1, 2, 4] {
            let frame = try AnnexB.accessUnit(lengthPrefixed: Data(repeating: 0, count: width - 1) + Data([1, 0x41]),
                                             lengthBytes: width, parameterSets: [], sequence: 1, generation: 7)
            XCTAssertEqual(frame.bytes, Data([0, 0, 0, 1, 0x41])); XCTAssertFalse(frame.isKeyframe)
        }
    }

    func testAnnexBRejectsMalformedLengthsForbiddenBitsAndMissingSets() {
        for bytes in [Data(), Data([0]), Data([0, 0, 0, 0]), Data([0xff, 0xff, 0xff, 0xff]),
                      Data([0, 0, 0, 2, 0x41]), Data([0, 0, 0, 1, 0x80]), Data([0, 0, 0, 1, 0x65])] {
            XCTAssertThrowsError(try AnnexB.accessUnit(lengthPrefixed: bytes, lengthBytes: 4, parameterSets: [], sequence: 0, generation: 1))
        }
        XCTAssertThrowsError(try AnnexB.accessUnit(lengthPrefixed: Data([1, 0x41]), lengthBytes: 3, parameterSets: [], sequence: 0, generation: 1))
    }

    func testQueueOverflowInvalidatesDependentChainUntilFreshIDR() throws {
        var queue = try FrameQueue(maximumFrames: 2, maximumBytes: 8)
        queue.start(generation: 1)
        XCTAssertEqual(queue.admit(unit(0)), .needsKeyframe)
        XCTAssertEqual(queue.admit(unit(1, keyframe: true)), .accepted)
        XCTAssertEqual(queue.admit(unit(2)), .accepted)
        XCTAssertEqual(queue.admit(unit(3)), .needsKeyframe)
        XCTAssertEqual(queue.count, 0); XCTAssertNil(queue.pull()); XCTAssertTrue(queue.waitingForKeyframe)
        XCTAssertEqual(queue.admit(unit(4)), .needsKeyframe)
        XCTAssertEqual(queue.admit(unit(5, keyframe: true)), .accepted)
        XCTAssertEqual(queue.pull()?.sequence, 5)
    }

    func testQueueByteBudgetStartStopAndStaleGeneration() throws {
        var queue = try FrameQueue(maximumFrames: 3, maximumBytes: 5)
        XCTAssertEqual(queue.admit(unit(0, keyframe: true)), .ignored)
        queue.start(generation: 1)
        XCTAssertEqual(queue.admit(unit(0, keyframe: true, size: 4)), .accepted)
        XCTAssertEqual(queue.admit(unit(1)), .needsKeyframe)
        XCTAssertEqual(queue.bufferedByteCount, 0)
        XCTAssertEqual(queue.admit(unit(2, keyframe: true, size: 6)), .needsKeyframe)
        XCTAssertEqual(queue.admit(unit(3, keyframe: true)), .accepted)
        queue.start(generation: 2)
        XCTAssertEqual(queue.admit(unit(4, keyframe: true)), .ignored)
        XCTAssertNil(queue.pull())
        XCTAssertEqual(queue.admit(unit(5, keyframe: true, generation: 2)), .accepted)
        queue.stop(); queue.stop()
        XCTAssertEqual(queue.admit(unit(6, keyframe: true, generation: queue.generation)), .ignored)
        XCTAssertEqual(queue.count, 0)
        XCTAssertThrowsError(try FrameQueue(maximumFrames: 0))
    }

    func testSyntheticGeometryAndMovingPixelBuffer() throws {
        XCTAssertThrowsError(try SyntheticFrameSource(width: 15, height: 384))
        let source = try SyntheticFrameSource(width: 800, height: 384)
        let first = try source.frame(sequence: 0), second = try source.frame(sequence: 1)
        XCTAssertEqual(CVPixelBufferGetWidth(first), 800)
        XCTAssertEqual(CVPixelBufferGetHeight(first), 384)
        XCTAssertEqual(CVPixelBufferGetPixelFormatType(first), kCVPixelFormatType_32BGRA)
        for (buffer, expected) in [(first, UInt8(240)), (second, UInt8(20))] {
            XCTAssertEqual(CVPixelBufferLockBaseAddress(buffer, .readOnly), kCVReturnSuccess)
            let row = CVPixelBufferGetBaseAddress(buffer)!.advanced(by: 336 * CVPixelBufferGetBytesPerRow(buffer)).assumingMemoryBound(to: UInt8.self)
            XCTAssertEqual(row[0], expected)
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
    }

    func testPostSubmissionFlushFailurePermanentlyClosesEncoder() throws {
        let source = try SyntheticFrameSource(width: 800, height: 384)
        var submissions = 0
        let encoder = try H264Encoder(width: 800, height: 384, framesPerSecond: 30, submit: { session, buffer, time, duration, properties, output in
            submissions += 1
            return VTCompressionSessionEncodeFrame(session, imageBuffer: buffer, presentationTimeStamp: time, duration: duration,
                                                    frameProperties: properties, infoFlagsOut: nil, outputHandler: output)
        }, flush: { _ in -12900 })
        XCTAssertThrowsError(try encoder.encode(source.frame(sequence: 0), sequence: 0, generation: 1, forceKeyframe: true)) {
            XCTAssertEqual($0 as? VideoError, .frameworkFailure(-12900))
        }
        XCTAssertThrowsError(try encoder.encode(source.frame(sequence: 1), sequence: 1, generation: 1, forceKeyframe: false)) {
            XCTAssertEqual($0 as? VideoError, .invalidFrame)
        }
        XCTAssertEqual(submissions, 1)
    }

    func testMissingOutputAndSubmissionFailureAreTerminal() throws {
        let source = try SyntheticFrameSource(width: 800, height: 384)
        for status: OSStatus in [noErr, -12900] {
            let encoder = try H264Encoder(width: 800, height: 384, framesPerSecond: 30, submit: { _, _, _, _, _, output in
                output(noErr, [], nil)
                return status
            }, flush: { _ in noErr })
            XCTAssertThrowsError(try encoder.encode(source.frame(sequence: 0), sequence: 0, generation: 1, forceKeyframe: true)) {
                XCTAssertEqual($0 as? VideoError, status == noErr ? .missingOutput : .frameworkFailure(status))
            }
            XCTAssertThrowsError(try encoder.encode(source.frame(sequence: 1), sequence: 1, generation: 1, forceKeyframe: false)) {
                XCTAssertEqual($0 as? VideoError, .invalidFrame)
            }
        }
    }
}
