// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the pixel format of a depth image buffer.
///
/// In general, depth formats use actual depth sensors, like infrared, time-of-flight, or LiDAR. Disparity
/// formats come from multiple constituent physical Cameras and represent pixel shift between two or more
/// Cameras.
public enum DepthPixelFormat: CaseIterable, Sendable {
  /// The depth pixel format is unknown.
  case unknown
  /// Depth values stored as 16-bit floating-point samples.
  case depth16Bit
  /// Depth values stored as 32-bit floating-point samples.
  case depth32Bit
  /// Disparity values stored as 16-bit floating-point samples.
  case disparity16Bit
  /// Disparity values stored as 32-bit floating-point samples.
  case disparity32Bit

}
