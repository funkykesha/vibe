import XCTest
@testable import StartWatch

final class IPCFrameCodecTests: XCTestCase {
    func testEncodeAndDecodeSingleFrame() throws {
        let payload = Data("{\"action\":\"trigger_check\"}".utf8)
        let framed = try IPCFrameCodec.encode(payload)

        var decoder = IPCFrameDecoder()
        let decoded = try decoder.append(framed)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first, payload)
    }

    func testDecodeMultipleFramesFromSingleStreamChunk() throws {
        let first = Data("{\"action\":\"a\"}".utf8)
        let second = Data("{\"action\":\"b\"}".utf8)
        var stream = Data()
        stream.append(try IPCFrameCodec.encode(first))
        stream.append(try IPCFrameCodec.encode(second))

        var decoder = IPCFrameDecoder()
        let decoded = try decoder.append(stream)

        XCTAssertEqual(decoded.count, 2)
        guard decoded.count == 2 else { return }
        XCTAssertEqual(decoded[0], first)
        XCTAssertEqual(decoded[1], second)
    }

    func testDecodeBuffersPartialFrameUntilComplete() throws {
        let payload = Data("{\"action\":\"partial\"}".utf8)
        let framed = try IPCFrameCodec.encode(payload)

        let splitIndex = 6
        let partA = framed.prefix(splitIndex)
        let partB = framed.dropFirst(splitIndex)

        var decoder = IPCFrameDecoder()
        let firstPass = try decoder.append(Data(partA))
        XCTAssertTrue(firstPass.isEmpty)

        let secondPass = try decoder.append(Data(partB))
        XCTAssertEqual(secondPass.count, 1)
        XCTAssertEqual(secondPass.first, payload)
    }

    func testMalformedFrameLengthThrowsAndResetsBuffer() throws {
        var decoder = IPCFrameDecoder()

        var invalidLength = UInt32.max.bigEndian
        let invalidPrefix = Data(bytes: &invalidLength, count: MemoryLayout<UInt32>.size)

        XCTAssertThrowsError(try decoder.append(invalidPrefix)) { error in
            guard case IPCFrameDecoder.DecodeError.invalidFrameLength(let value) = error else {
                return XCTFail("Expected invalidFrameLength error")
            }
            XCTAssertEqual(value, UInt32.max)
        }

        let validPayload = Data("{\"action\":\"ok\"}".utf8)
        let validFrame = try IPCFrameCodec.encode(validPayload)
        let decoded = try decoder.append(validFrame)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first, validPayload)
    }
}
