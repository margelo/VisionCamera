// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the resize mode for the ``PreviewView``.
/// - ``PreviewResizeMode/aspectFill``: Upscales the ``PreviewView`` to cover up the entire view and leave no blank space, possibly performing a center-crop transform
/// to make up for aspect ratio differences.
/// - ``PreviewResizeMode/aspectFit``: Centers the ``PreviewView`` inside the view, possibly leaving blank space around the top/bottom, or left/right edges to
/// make up for aspect ratio differences.
public enum PreviewResizeMode: CaseIterable, Sendable {
  /// Upscales the ``PreviewView`` to cover up the entire view and leave no blank space, possibly performing
  /// a center-crop transform to make up for aspect ratio differences.
  case aspectFill
  /// Centers the ``PreviewView`` inside the view, possibly leaving blank space around the top/bottom, or
  /// left/right edges to make up for aspect ratio differences.
  case aspectFit

}
