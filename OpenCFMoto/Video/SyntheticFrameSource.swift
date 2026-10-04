import CoreVideo
import Foundation

public struct SyntheticFrameSource {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) throws {
        guard width >= 16, height >= 16, width <= 4096, height <= 4096,
              width.isMultiple(of: 16), height.isMultiple(of: 16) else { throw VideoError.invalidConfiguration }
        self.width = width; self.height = height
    }

    public func frame(sequence: UInt64) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let attributes = [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes, &buffer)
        guard status == kCVReturnSuccess, let buffer else { throw VideoError.frameworkFailure(status) }
        let lockStatus = CVPixelBufferLockBaseAddress(buffer, [])
        guard lockStatus == kCVReturnSuccess else { throw VideoError.frameworkFailure(lockStatus) }
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { throw VideoError.invalidFrame }
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        let markerWidth = max(16, width / 8)
        let markerX = Int(sequence % UInt64((width - markerWidth) / 16 + 1)) * 16
        for y in 0..<height {
            let row = base.advanced(by: y * stride).assumingMemoryBound(to: UInt8.self)
            for x in 0..<width {
                let offset = x * 4
                var red: UInt8 = 20, green: UInt8 = 20, blue: UInt8 = 20
                if y < height * 3 / 4 {
                    switch min(2, x * 3 / width) {
                    case 0: red = 240
                    case 1: green = 240
                    default: blue = 240
                    }
                } else if (markerX..<(markerX + markerWidth)).contains(x) {
                    red = 240; green = 240; blue = 240
                }
                row[offset] = blue; row[offset + 1] = green; row[offset + 2] = red; row[offset + 3] = 255
            }
        }
        return buffer
    }
}
