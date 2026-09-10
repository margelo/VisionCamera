import CoreMedia
import CoreVideo
import VisionCamera
import VisionCameraResizer
import XCTest

final class GPUResizerTests: XCTestCase {
  func testConfigurationAndUnsupportedInputFailWithoutGPUInitialization() throws {
    for (width, height) in [(0, 8), (8, -1), (Int.max, 2), (65_536, 65_536)] {
      XCTAssertThrowsError(try GPUResizer(options: ResizerOptions(width: width, height: height))) { error in
        XCTAssertEqual(error as? GPUResizerError, .invalidDimensions)
      }
    }
    XCTAssertThrowsError(try GPUResizer(options: ResizerOptions(width: 2, height: 2), maximumOutstandingResults: 0)) { error in
      XCTAssertEqual(error as? GPUResizerError, .invalidCapacity)
    }
    let resizer = try GPUResizer(options: ResizerOptions(width: 2, height: 2))
    var buffer: CVPixelBuffer?
    XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 2, 2, kCVPixelFormatType_32BGRA, nil, &buffer), kCVReturnSuccess)
    XCTAssertThrowsError(try resizer.resize(XCTUnwrap(buffer))) { error in
      XCTAssertEqual(error as? GPUResizerError, .unsupportedPixelFormat(kCVPixelFormatType_32BGRA))
    }
  }

  func testInstalledShaderSupportsEveryOutputEncodingAndLayout() throws {
    try ResizerTestImage.requireMetal()
    let luma: [UInt8] = [32, 64, 96, 128, 160, 192, 224, 255]
    let input = try ResizerTestImage.make(luma: luma, cb: 64, cr: 192)
    for type in ResizerDataType.allCases {
      for order in ResizerChannelOrder.allCases {
        for layout in ResizerPixelLayout.allCases {
          let options = ResizerOptions(width: 4, height: 2, channelOrder: order, dataType: type, pixelLayout: layout)
          let result = try GPUResizer(options: options).resize(input)
          XCTAssertEqual(result.width, 4)
          XCTAssertEqual(result.height, 2)
          XCTAssertEqual(result.byteCount, 4 * 2 * 3 * type.bytesPerChannel)
          XCTAssertEqual(result.channelOrder, order)
          XCTAssertEqual(result.pixelLayout, layout)
          let values = ResizerTestImage.values(result)
          for (pixel, yByte) in luma.enumerated() {
            let y = Double(yByte) / 255
            let cb = 64.0 / 255 - 0.5
            let cr = 192.0 / 255 - 0.5
            let rgb = [y + 1.402 * cr, y - 0.344136 * cb - 0.714136 * cr, y + 1.772 * cb].map { min(1, max(0, $0)) }
            let channels = order == .rgb ? rgb : Array(rgb.reversed())
            for channel in 0..<3 {
              let index = layout == .interleaved ? pixel * 3 + channel : channel * luma.count + pixel
              let normalized = channels[channel]
              let expected: Double
              switch type {
              case .uint8: expected = (normalized * 255).rounded(.toNearestOrEven)
              case .int8: expected = (normalized * 255).rounded(.toNearestOrEven) - 128
              case .float16, .float32: expected = normalized
              }
              let accuracy = type == .uint8 || type == .int8 ? 1.0 : 0.001
              XCTAssertEqual(values[index], expected, accuracy: accuracy, "\(type), \(order), \(layout), pixel \(pixel), channel \(channel)")
            }
          }
        }
      }
    }
  }

  func testCropContainAndBilinearStretch() throws {
    try ResizerTestImage.requireMetal()
    let input = try ResizerTestImage.make(luma: [20, 50, 80, 110, 140, 170, 200, 230])
    let crop = try GPUResizer(options: ResizerOptions(width: 2, height: 2, scaleMode: .cover)).resize(input)
    ResizerTestImage.assertLuma(crop, [50, 80, 170, 200])
    let contain = try GPUResizer(options: ResizerOptions(width: 4, height: 4, scaleMode: .contain)).resize(input)
    ResizerTestImage.assertLuma(contain, [0, 0, 0, 0, 20, 50, 80, 110, 140, 170, 200, 230, 0, 0, 0, 0])
    let stretch = try GPUResizer(options: ResizerOptions(width: 2, height: 2, scaleMode: .stretch)).resize(input)
    ResizerTestImage.assertLuma(stretch, [35, 95, 155, 215])
  }

  func testRotationAndSourceAxisMirroring() throws {
    try ResizerTestImage.requireMetal()
    let input = try ResizerTestImage.make(luma: [20, 50, 80, 110, 140, 170, 200, 230])
    let cases: [(CameraOrientation, Bool, Int, Int, [Double])] = [
      (.up, false, 4, 2, [20, 50, 80, 110, 140, 170, 200, 230]),
      (.right, false, 2, 4, [140, 20, 170, 50, 200, 80, 230, 110]),
      (.down, false, 4, 2, [230, 200, 170, 140, 110, 80, 50, 20]),
      (.left, false, 2, 4, [110, 230, 80, 200, 50, 170, 20, 140]),
      (.up, true, 4, 2, [110, 80, 50, 20, 230, 200, 170, 140]),
      (.right, true, 2, 4, [230, 110, 200, 80, 170, 50, 140, 20]),
      (.down, true, 4, 2, [140, 170, 200, 230, 20, 50, 80, 110]),
      (.left, true, 2, 4, [20, 140, 50, 170, 80, 200, 110, 230]),
    ]
    for (orientation, mirrored, width, height, expected) in cases {
      let resizer = try GPUResizer(options: ResizerOptions(width: width, height: height))
      let frame = try ResizerTestImage.frame(input, orientation: orientation, isMirrored: mirrored)
      let result = try resizer.resize(frame)
      CMSampleBufferInvalidate(frame.sampleBuffer)
      ResizerTestImage.assertLuma(result, expected)
      XCTAssertThrowsError(try resizer.resize(frame))
    }
  }

  func testNonMultipleThreadgroupDimensionsAndSignedBlackPadding() throws {
    try ResizerTestImage.requireMetal()
    let input = try ResizerTestImage.make(luma: Array(repeating: 128, count: 8))
    let result = try GPUResizer(options: ResizerOptions(width: 19, height: 7)).resize(input)
    XCTAssertEqual(result.byteCount, 19 * 7 * 3)
    ResizerTestImage.assertLuma(result, Array(repeating: 128, count: 19 * 7))
    let signed = try GPUResizer(options: ResizerOptions(width: 4, height: 4, dataType: .int8, scaleMode: .contain)).resize(input)
    XCTAssertEqual(Array(ResizerTestImage.values(signed).prefix(12)), Array(repeating: -128, count: 12))
  }
}
