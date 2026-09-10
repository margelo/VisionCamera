// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the reason why a ``Frame`` was dropped by the Camera pipeline.
/// - ``FrameDroppedReason/frameWasLate``: The Frame took too long to process and could not be delivered in time.
/// - ``FrameDroppedReason/outOfBuffers``: The Camera pipeline ran out of available buffers, most likely because previous
///   Frames were not disposed (``Frame/dispose()``) fast enough.
/// - ``FrameDroppedReason/discontinuity``: A discontinuity in the Frame stream occurred, typically when the Camera session
///   was interrupted or reconfigured.
/// - ``FrameDroppedReason/unknown``: The Frame was dropped for an unknown reason.
public enum FrameDroppedReason: CaseIterable, Sendable {
  /// The Frame was dropped for an unknown reason.
  case unknown
  /// The Frame took too long to process and could not be delivered in time.
  case frameWasLate
  /// The Camera pipeline ran out of available buffers, most likely because previous Frames were not disposed
  /// (``Frame/dispose()``) fast enough.
  case outOfBuffers
  /// A discontinuity in the Frame stream occurred, typically when the Camera session was interrupted or
  /// reconfigured.
  case discontinuity

}
