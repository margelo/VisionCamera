// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the AVFoundation Camera type of a ``CameraDevice``.
///
/// Single-lens, depth-capable, and external Cameras include:
/// - ``DeviceType/wideAngle``: The default Camera, with a wide field of view.
/// - ``DeviceType/ultraWideAngle``: A very wide-angle lens, typically capturing a much larger field of view.
/// - ``DeviceType/telephoto``: A lens with a longer focal length, used for optical zoom.
/// - ``DeviceType/continuity``: An external Continuity Camera (iPhone used as a Camera on macOS).
/// - ``DeviceType/lidarDepth``: A LiDAR depth Camera with an associated YUV Camera.
/// - ``DeviceType/trueDepth``: A TrueDepth Camera with infrared and YUV Cameras.
/// - ``DeviceType/external``: A generic external Camera (e.g. USB).
/// - ``DeviceType/unknown``: The Camera type is unknown or not reported.
///
/// Virtual multi-lens Cameras combine multiple physical Cameras into one:
/// - ``DeviceType/dual``: A logical combination of a wide-angle and a telephoto lens.
/// - ``DeviceType/dualWide``: A logical combination of a wide-angle and an ultra-wide-angle lens.
/// - ``DeviceType/triple``: A logical combination of three physical Cameras (typically ultra-wide, wide, and telephoto).
///
/// See ``CameraDevice/physicalDevices``
public enum DeviceType: CaseIterable, Sendable {
  /// The Camera type is unknown or not reported.
  case unknown
  /// The default Camera, with a wide field of view.
  case wideAngle
  /// A very wide-angle lens, typically capturing a much larger field of view.
  case ultraWideAngle
  /// A lens with a longer focal length, used for optical zoom.
  case telephoto
  /// A logical combination of a wide-angle and a telephoto lens.
  case dual
  /// A logical combination of a wide-angle and an ultra-wide-angle lens.
  case dualWide
  /// A logical combination of three physical Cameras (typically ultra-wide, wide, and telephoto).
  case triple
  /// An external Continuity Camera (iPhone used as a Camera on macOS).
  case continuity
  /// A LiDAR depth Camera with an associated YUV Camera.
  case lidarDepth
  /// A TrueDepth Camera with infrared and YUV Cameras.
  case trueDepth
  /// A generic external Camera (e.g. USB).
  case external

}
