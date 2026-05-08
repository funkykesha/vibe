import Foundation

enum IPCFrameCodecError: Error, Equatable {
    case payloadTooLarge(Int)
}

enum IPCFrameCodec {
    private static let lengthSize = MemoryLayout<UInt32>.size

    static func encode(_ payload: Data) throws -> Data {
        guard payload.count <= Int(UInt32.max) else {
            throw IPCFrameCodecError.payloadTooLarge(payload.count)
        }

        var length = UInt32(payload.count).bigEndian
        var data = Data(bytes: &length, count: lengthSize)
        data.append(payload)
        return data
    }
}

struct IPCFrameDecoder {
    enum DecodeError: Error, Equatable {
        case invalidFrameLength(UInt32)
    }

    private static let maxFrameLength = 8 * 1024 * 1024
    private var buffer: [UInt8] = []

    mutating func append(_ chunk: Data) throws -> [Data] {
        if !chunk.isEmpty {
            buffer.append(contentsOf: chunk)
        }

        var frames: [Data] = []
        while true {
            guard buffer.count >= MemoryLayout<UInt32>.size else {
                return frames
            }

            let b0 = UInt32(buffer[0])
            let b1 = UInt32(buffer[1])
            let b2 = UInt32(buffer[2])
            let b3 = UInt32(buffer[3])
            let declaredLength = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3

            guard declaredLength <= UInt32(Self.maxFrameLength) else {
                buffer.removeAll(keepingCapacity: false)
                throw DecodeError.invalidFrameLength(declaredLength)
            }

            let fullFrameSize = MemoryLayout<UInt32>.size + Int(declaredLength)
            guard buffer.count >= fullFrameSize else {
                return frames
            }

            let payloadBytes = Array(buffer[MemoryLayout<UInt32>.size..<fullFrameSize])
            frames.append(Data(payloadBytes))
            buffer.removeFirst(fullFrameSize)
        }
    }
}
