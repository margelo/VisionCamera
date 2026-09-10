// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies the metering mode, also known as the 3A operation.
/// - ``MeteringMode/ae``: Auto-Exposure - requires ``CameraDevice/supportsExposureMetering``
/// - ``MeteringMode/af``: Auto-Focus - requires ``CameraDevice/supportsFocusMetering``
/// - ``MeteringMode/awb``: Auto-White-Balance - requires ``CameraDevice/supportsWhiteBalanceMetering``
///
/// See ``CameraController/focus(at:options:)``
/// See ``FocusOptions``
public enum MeteringMode: CaseIterable, Sendable {
  /// Auto-Exposure - requires ``CameraDevice/supportsExposureMetering``.
  case ae
  /// Auto-Focus - requires ``CameraDevice/supportsFocusMetering``.
  case af
  /// Auto-White-Balance - requires ``CameraDevice/supportsWhiteBalanceMetering``.
  case awb

}
