import Foundation
import XCTest
@testable import OpenCFMotoCore

final class WriteQueueTests: XCTestCase {
    func testInvalidLimitsAndUnexpectedCompletionAreTypedErrors() throws {
        for (count, bytes) in [(0, 1), (1, 0), (-1, 1), (1, -1)] {
            XCTAssertThrowsError(try WriteQueue(maximumWrites: count, maximumBytes: bytes)) {
                XCTAssertEqual($0 as? WriteQueueError, .invalidLimits)
            }
        }
        var queue = try WriteQueue()
        XCTAssertThrowsError(try queue.completeWrite()) { XCTAssertEqual($0 as? WriteQueueError, .noWriteInFlight) }
        try queue.enqueue([])
        XCTAssertNil(queue.next())
    }

    func testFIFOAllowsOnlyOneInFlightWrite() throws {
        var queue = try WriteQueue()
        let first = Data([1, 2]), second = Data([3])
        try queue.enqueue([first, second])
        XCTAssertEqual(queue.next(), first)
        XCTAssertNil(queue.next())
        XCTAssertTrue(queue.isWriting)
        XCTAssertEqual(queue.pendingWriteCount, 2)
        XCTAssertEqual(queue.bufferedByteCount, 3)
        try queue.completeWrite()
        XCTAssertFalse(queue.isWriting)
        XCTAssertEqual(queue.next(), second)
        try queue.completeWrite()
        XCTAssertNil(queue.next())
        XCTAssertEqual(queue.pendingWriteCount, 0)
        XCTAssertEqual(queue.bufferedByteCount, 0)
    }

    func testStalledWriteStillConsumesByteCapacity() throws {
        var queue = try WriteQueue(maximumWrites: 3, maximumBytes: 5)
        try queue.enqueue([Data(repeating: 1, count: 4), Data([2])])
        XCTAssertNotNil(queue.next())
        XCTAssertThrowsError(try queue.enqueue([Data([3])])) { XCTAssertEqual($0 as? WriteQueueError, .capacityExceeded) }
        XCTAssertEqual(queue.bufferedByteCount, 5)
        try queue.completeWrite()
        try queue.enqueue([Data(repeating: 3, count: 4)])
        XCTAssertEqual(queue.bufferedByteCount, 5)
    }

    func testCountCapacityAndRejectedBatchesAreAtomic() throws {
        var queue = try WriteQueue(maximumWrites: 2, maximumBytes: 5)
        try queue.enqueue([Data([1])])
        XCTAssertNotNil(queue.next())
        for batch in [[Data([2]), Data([3])], [Data(repeating: 2, count: 5)], [Data([2]), Data()]] {
            XCTAssertThrowsError(try queue.enqueue(batch))
            XCTAssertEqual(queue.pendingWriteCount, 1)
            XCTAssertEqual(queue.bufferedByteCount, 1)
            XCTAssertTrue(queue.isWriting)
        }
        try queue.enqueue([Data([2])])
        XCTAssertThrowsError(try queue.enqueue([Data([3])])) { XCTAssertEqual($0 as? WriteQueueError, .capacityExceeded) }
        try queue.completeWrite()
        XCTAssertEqual(queue.next(), Data([2]))

        var empty = try WriteQueue()
        XCTAssertThrowsError(try empty.enqueue([Data([1]), Data()])) { XCTAssertEqual($0 as? WriteQueueError, .emptyWrite) }
        XCTAssertEqual(empty.pendingWriteCount, 0)
    }

    func testClosePurgesAndRejectsLateCompletionWithoutReopening() throws {
        var queue = try WriteQueue()
        try queue.enqueue([Data([1]), Data([2])])
        XCTAssertNotNil(queue.next())
        queue.close(); queue.close()
        XCTAssertFalse(queue.isWriting)
        XCTAssertEqual(queue.pendingWriteCount, 0)
        XCTAssertEqual(queue.bufferedByteCount, 0)
        XCTAssertNil(queue.next())
        XCTAssertThrowsError(try queue.completeWrite()) { XCTAssertEqual($0 as? WriteQueueError, .closed) }
        XCTAssertThrowsError(try queue.enqueue([Data([3])])) { XCTAssertEqual($0 as? WriteQueueError, .closed) }
    }

    func testConnectionsHaveIndependentBudgetsAndDefaultBound() throws {
        var stalled = try WriteQueue(maximumWrites: 1, maximumBytes: 1)
        var active = try WriteQueue(maximumWrites: 1, maximumBytes: 1)
        try stalled.enqueue([Data([1])]); XCTAssertNotNil(stalled.next())
        try active.enqueue([Data([2])]); XCTAssertEqual(active.next(), Data([2]))
        try active.completeWrite()
        XCTAssertTrue(stalled.isWriting)
        XCTAssertEqual(active.pendingWriteCount, 0)
        var defaults = try WriteQueue()
        XCTAssertThrowsError(try defaults.enqueue([Data(repeating: 0, count: defaults.maximumBytes + 1)])) {
            XCTAssertEqual($0 as? WriteQueueError, .capacityExceeded)
        }
        try defaults.enqueue([Data(repeating: 0, count: defaults.maximumBytes)])
        XCTAssertEqual(defaults.bufferedByteCount, defaults.maximumBytes)
    }
}
