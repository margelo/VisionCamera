// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the auto-focus algorithm used by the ``CameraDevice``, either while
/// continuously keeping a scene in focus (via auto-3A / AE/AF/AWB), or for a metering
/// action via ``CameraController/focus(at:options:)``.
///
/// - ``AutoFocusSystem/none``: The ``CameraDevice`` does not support auto-focus at all.
/// - ``AutoFocusSystem/contrastDetection``: Finds focus by adjusting the lens until image contrast is highest.
///   Commonly supported, but generally slower than phase-detection.
/// - ``AutoFocusSystem/phaseDetection``: Finds focus by using phase information to predict the correct lens position.
///   Generally the fastest and most reliable auto-focus system when available.
public enum AutoFocusSystem: CaseIterable, Sendable {
  /// The ``CameraDevice`` does not support auto-focus at all.
  case none
  /// Finds focus by adjusting the lens until image contrast is highest. Commonly supported, but generally
  /// slower than phase-detection.
  case contrastDetection
  /// Finds focus by using phase information to predict the correct lens position. Generally the fastest and
  /// most reliable auto-focus system when available.
  case phaseDetection

}
