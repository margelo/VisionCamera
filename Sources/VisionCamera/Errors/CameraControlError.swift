// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// A Camera control that is unsupported or has an invalid value.
///
/// Camera controls also propagate AVFoundation errors and task cancellation unchanged.
public enum CameraControlError: Error, LocalizedError {
  /// The Camera does not support the requested control.
  case unsupportedFeature(Feature)
  /// A control value is outside the range supported by the current Camera configuration.
  case valueOutOfRange(parameter: Parameter, value: Double, allowed: ClosedRange<Double>)
  /// The Camera does not support the requested metering mode.
  case unsupportedMeteringMode(MeteringMode)
  /// A focus operation requires at least one metering mode.
  case emptyMeteringModes
  /// The requested focus, exposure, or white-balance metering did not settle before its timeout.
  case meteringTimedOut
  /// A zoom ramp requires a positive, finite rate representable by AVFoundation.
  case invalidZoomRampRate(Double)

  /// A Camera capability needed for a control operation.
  public enum Feature: Sendable {
    /// Automatic exposure boost in low light.
    case lowLightBoost
    /// Smooth automatic focus adjustments.
    case smoothAutoFocus
    /// Geometric lens distortion correction.
    case distortionCorrection
    /// Continuous illumination from the flash.
    case torch
    /// A custom torch brightness.
    case torchStrength
    /// Locking focus at a lens position.
    case focusLock
    /// Locking exposure duration and ISO.
    case exposureLock
    /// Locking white balance with custom channel gains.
    case whiteBalanceLock
  }

  /// A numeric Camera control parameter.
  public enum Parameter: Sendable {
    /// The video zoom factor.
    case zoom
    /// The torch brightness.
    case torchStrength
    /// The automatic exposure bias, in EV.
    case exposureBias
    /// The normalized lens position.
    case lensPosition
    /// The exposure duration, in seconds.
    case exposureDuration
    /// The sensor sensitivity.
    case iso
    /// The red white-balance gain.
    case redGain
    /// The green white-balance gain.
    case greenGain
    /// The blue white-balance gain.
    case blueGain
  }

  /// A description of the unsupported control or invalid value.
  public var errorDescription: String? {
    switch self {
    case .unsupportedFeature(let feature):
      return "This Camera does not support \(feature)."
    case .valueOutOfRange(let parameter, let value, let allowed):
      return "\(parameter) must be between \(allowed.lowerBound) and \(allowed.upperBound). Received \(value)."
    case .unsupportedMeteringMode(let mode):
      return "This Camera does not support \(mode) metering."
    case .emptyMeteringModes:
      return "A focus operation requires at least one metering mode."
    case .meteringTimedOut:
      return "The metering operation did not settle before its timeout."
    case .invalidZoomRampRate(let rate):
      return "The zoom ramp rate must be positive and finite. Received \(rate)."
    }
  }
}
