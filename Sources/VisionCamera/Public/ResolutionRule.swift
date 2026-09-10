// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics

/// The target resolution rule evaluated while negotiating a Camera format.
public enum ResolutionRule: Equatable, Sendable {
  /// Prefer the supported resolution closest to the supplied size, prioritizing aspect ratio before pixel count.
  case closest(to: CGSize)
  /// Prefer resolutions at least as large as the supplied size, ignoring aspect ratio and dimension order.
  case atLeast(CGSize)
  /// Accept any supported resolution without a size preference.
  case any
}
