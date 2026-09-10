// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a desired pixel format for a video
/// pipeline.
///
/// Used to configure the format a ``FrameOutput``
/// streams ``Frame``s in.
///
/// - ``TargetVideoPixelFormat/native``: Choose whatever the ``CameraSessionConfig``'s
///    ``CameraSessionConfig/nativePixelFormat`` is. This can be a YUV format,
///    an RGB format like ``PixelFormat/rgbBgra8Bit``, a RAW format like
///    ``PixelFormat/rawBayerPacked9612Bit``, or a private
///    format (``PixelFormat/private``) and requires zero conversion.
/// - ``TargetVideoPixelFormat/yuv``: Choose the YUV format closest to the Camera's native format. Often YUV 4:2:0
///    8-bit full-range like ``PixelFormat/yuv4208BitFull``.
/// - ``TargetVideoPixelFormat/rgb``: Choose an RGB format. Often 8-bit BGRA like
///   ``PixelFormat/rgbBgra8Bit``.
public enum TargetVideoPixelFormat: CaseIterable, Sendable {
  /// Uses the Camera's native pixel format without requesting conversion.
  case native
  /// Requests full-range, bi-planar YUV 4:2:0 samples with 8 bits per component.
  case yuv
  /// Requests interleaved BGRA samples with 8 bits per channel.
  case rgb

}
