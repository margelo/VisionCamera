// Copyright © 2025 Marc Rousavy @ Margelo

/// The common interface for all outputs that can be connected to a ``CameraSession``.
///
/// Conform to this protocol and ``NativeCameraOutput`` to create custom outputs. This is useful for building
/// custom capture pipelines, such as private HDR implementations or custom video recording pipelines.
public protocol CameraOutput: AnyObject {
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  var mediaType: MediaType { get }
  /// Gets or sets the output orientation of this ``CameraOutput``.
  ///
  /// Individual implementations of ``CameraOutput``
  /// may choose different strategies for implementing
  /// output orientation, for example:
  /// - A Photo output might apply orientation via EXIF flags.
  /// - A Video output might apply orientation via track transform metadata.
  /// - A Preview output might apply orientation via view transforms.
  /// - A Frame output might not apply orientation and only pass it as a
  /// property via the `Frame` object, unless explicitly configured to
  /// physically rotate buffers.
  var outputOrientation: CameraOrientation { get set }
  /// The resolution that the underlying capture pipeline has resolved
  /// this ``CameraOutput`` to, in sensor-native (un-rotated) pixels,
  /// or `nil` if the output has not yet been connected to a
  /// ``CameraSession``.
  ///
  /// The selected ``Size`` may differ from the requested
  /// ``Size`` (e.g. from ``PhotoOutputOptions/targetResolution``),
  /// as the ``CameraSession`` negotiates resolutions across
  /// attached ``CameraOutput``s, connected ``CameraDevice``
  /// capabilities, and enabled ``Constraint``s.
  ///
  /// For outputs that are not pixel-based (e.g. metadata-only outputs),
  /// this reports the resolution of the upstream video stream feeding
  /// the output, or `nil` if no video input is attached.
  var currentResolution: Size? { get }
}
