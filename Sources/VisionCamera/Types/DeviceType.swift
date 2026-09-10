// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the type of a physical or logical Camera lens on the ``CameraDevice``.
///
/// Physical Cameras are single hardware lenses:
/// - ``DeviceType/wideAngle``: The default Camera, with a wide field of view.
/// - ``DeviceType/ultraWideAngle``: A very wide-angle lens, typically capturing a much larger field of view.
/// - ``DeviceType/telephoto``: A lens with a longer focal length, used for optical zoom.
/// - ``DeviceType/continuity``: An external Continuity Camera (iPhone used as a Camera on macOS).
/// - ``DeviceType/lidarDepth``: A LiDAR-based depth sensor.
/// - ``DeviceType/trueDepth``: A structured-light based depth sensor (such as the FaceID front Camera).
/// - ``DeviceType/timeOfFlightDepth``: A time-of-flight based depth sensor.
/// - ``DeviceType/external``: A generic external Camera (e.g. USB).
/// - ``DeviceType/unknown``: The Camera type is unknown or not reported.
///
/// Logical Cameras are virtual Cameras that combine multiple physical Cameras into one:
/// - ``DeviceType/dual``: A logical combination of a wide-angle and a telephoto lens.
/// - ``DeviceType/dualWide``: A logical combination of a wide-angle and an ultra-wide-angle lens.
/// - ``DeviceType/triple``: A logical combination of three physical Cameras (typically ultra-wide, wide, and telephoto).
/// - ``DeviceType/quad``: A logical combination of four physical Cameras.
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
  /// A logical combination of four physical Cameras.
  case quad
  /// An external Continuity Camera (iPhone used as a Camera on macOS).
  case continuity
  /// A LiDAR-based depth sensor.
  case lidarDepth
  /// A structured-light based depth sensor (such as the FaceID front Camera).
  case trueDepth
  /// A time-of-flight based depth sensor.
  case timeOfFlightDepth
  /// A generic external Camera (e.g. USB).
  case external

}
