// Copyright © 2025 Marc Rousavy @ Margelo

/// The fixed output dimensions and tensor encoding used by a ``GPUResizer``.
public struct ResizerOptions: Sendable {
  /// The output width in pixels.
  public let width: Int
  /// The output height in pixels.
  public let height: Int
  /// The order of the three color channels.
  public let channelOrder: ResizerChannelOrder
  /// The scalar encoding of each channel.
  public let dataType: ResizerDataType
  /// The arrangement of pixels and channels in the output buffer.
  public let pixelLayout: ResizerPixelLayout
  /// The mapping of the upright input into the output rectangle.
  public let scaleMode: ResizerScaleMode

  /// Creates an output configuration. ``GPUResizer/init(options:maximumOutstandingResults:)`` validates the dimensions.
  public init(
    width: Int,
    height: Int,
    channelOrder: ResizerChannelOrder = .rgb,
    dataType: ResizerDataType = .uint8,
    pixelLayout: ResizerPixelLayout = .interleaved,
    scaleMode: ResizerScaleMode = .cover
  ) {
    self.width = width
    self.height = height
    self.channelOrder = channelOrder
    self.dataType = dataType
    self.pixelLayout = pixelLayout
    self.scaleMode = scaleMode
  }

  func validatedByteCount() throws -> Int {
    guard width > 0, height > 0 else { throw GPUResizerError.invalidDimensions }
    let (pixelCount, pixelOverflow) = width.multipliedReportingOverflow(by: height)
    let (channelCount, channelOverflow) = pixelCount.multipliedReportingOverflow(by: 3)
    let (byteCount, byteOverflow) = channelCount.multipliedReportingOverflow(by: dataType.bytesPerChannel)
    guard !pixelOverflow, !channelOverflow, !byteOverflow, channelCount <= Int(UInt32.max) else {
      throw GPUResizerError.invalidDimensions
    }
    return byteCount
  }
}
