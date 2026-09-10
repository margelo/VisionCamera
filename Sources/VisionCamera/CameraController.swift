///
/// CameraController.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// A ``CameraController`` allows controlling an opened
/// Camera.
///
/// After a ``CameraSession`` is reconfigured (e.g. when binding
/// new inputs, outputs, or connection settings), you receive a new
/// ``CameraController``.
///
/// ```swift
/// let controllers = try await session.configure([
///   CameraSessionConnection(input: .device(device), outputs: [])
/// ])
/// await session.start()
/// if let controller = controllers.first {
///   try await controller.setZoom(controller.maxZoom)
/// }
/// ```
public final class CameraController {
  /// Gets the ``CameraDevice`` this ``CameraController``
  /// is bound to.
  ///
  /// You can use the ``CameraController/device`` to query support for
  /// available features.
  ///
  /// ```swift
  /// let device = controller.device
  /// print(device.localizedName)
  /// ```
  public let device: CameraDevice
  /// The serial queue shared with this controller's ``CameraSession`` for AVFoundation configuration and controls.
  public let queue: DispatchQueue
  /// The underlying AVFoundation device controlled by this instance.
  public let captureDevice: AVCaptureDevice
  private var activeMeteringTask: MeteringTask? = nil

  init(device: CameraDevice, queue: DispatchQueue) {
    self.device = device
    self.captureDevice = device.device

    // TODO: Is it best practice to use the same `queue` as our CameraSession?
    self.queue = queue
  }

  /// Whether the underlying capture device is connected to the system.
  ///
  /// This describes device availability, not membership in a Camera session.
  public var isConnected: Bool {
    return captureDevice.isConnected
  }

  /// Gets whether this ``CameraController`` is
  /// currently suspended.
  ///
  /// A ``CameraController`` may be suspended when
  /// the system receives an interruption, such as thermal
  /// pressure.
  public var isSuspended: Bool {
    return captureDevice.isSuspended
  }

  /// The current native focus mode, including any future mode reported by AVFoundation.
  public var focusMode: AVCaptureDevice.FocusMode {
    return captureDevice.focusMode
  }

  /// The current native exposure mode. Manually configured duration and ISO use `.custom`.
  public var exposureMode: AVCaptureDevice.ExposureMode {
    return captureDevice.exposureMode
  }

  /// The current native white-balance mode, including any future mode reported by AVFoundation.
  public var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
    return captureDevice.whiteBalanceMode
  }

  /// The current white-balance gains reported by the device.
  ///
  /// Automatic white balance adjusts these gains across the scene. It does not use a point of interest.
  public var whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains {
    return captureDevice.deviceWhiteBalanceGains
  }

  /// Whether the device is currently applying low-light boost to captured images.
  ///
  /// You can enable low light boost via ``CameraController/configure(_:)``.
  ///
  /// ```swift
  /// if controller.device.supportsLowLightBoost {
  ///   try await controller.configure(CameraControllerConfiguration(isLowLightBoostEnabled: true))
  /// }
  /// ```
  public var isLowLightBoostEnabled: Bool {
    return captureDevice.isLowLightBoostEnabled
  }

  /// Gets whether smooth auto-focus is currently enabled.
  ///
  /// You can enable or disable smooth auto-focus via
  /// ``CameraController/configure(_:)`` if the ``CameraDevice``
  /// supports smooth auto-focus
  /// (see ``CameraDevice/supportsSmoothAutoFocus``).
  public var isSmoothAutoFocusEnabled: Bool {
    return captureDevice.isSmoothAutoFocusEnabled
  }

  /// Gets whether geometric distortion correction is currently enabled.
  ///
  /// You can enable or disable distortion correction via
  /// ``CameraController/configure(_:)`` if the ``CameraDevice``
  /// supports distortion correction (see
  /// ``CameraDevice/supportsDistortionCorrection``).
  public var isDistortionCorrectionEnabled: Bool {
    return captureDevice.isGeometricDistortionCorrectionEnabled
  }

  /// Represents the current zoom value.
  /// Zoom can be set via ``CameraController/setZoom(_:)``.
  public var zoom: Double {
    return captureDevice.videoZoomFactor
  }

  /// Represents the minimum value for the ``CameraController/setZoom(_:)``
  /// parameter in ``CameraController/setZoom(_:)``.
  public var minZoom: Double {
    return captureDevice.minAvailableVideoZoomFactor
  }

  /// Represents the maximum value for the ``CameraController/setZoom(_:)``
  /// parameter in ``CameraController/setZoom(_:)``.
  public var maxZoom: Double {
    return captureDevice.maxAvailableVideoZoomFactor
  }

  /// A user-displayable zoom factor.
  ///
  /// ```swift
  /// if #available(iOS 18.0, *) {
  ///   let zoomLabel = String(format: "%.1fx", controller.displayableZoomFactor)
  /// }
  /// ```
  @available(iOS 18.0, *)
  public var displayableZoomFactor: Double {
    return zoom * captureDevice.displayVideoZoomFactorMultiplier
  }

  /// The current torch brightness, from `0` when off to a theoretical maximum of `1`.
  ///
  /// The available brightness can decrease when the device overheats.
  public var torchLevel: Float {
    return captureDevice.torchLevel
  }

  /// The native torch mode, including automatic illumination when the device supports it.
  ///
  /// Set the mode with ``CameraController/setTorchMode(_:)`` or turn the torch on at a chosen
  /// brightness with ``CameraController/setTorchModeOn(level:)``.
  public var torchMode: AVCaptureDevice.TorchMode {
    return captureDevice.torchMode
  }

  /// The current lens position, from `0.0` at the nearest focus limit to `1.0` at the furthest.
  ///
  /// This normalized setting does not represent a distance in meters.
  ///
  /// The ``CameraController/lensPosition`` changes over time (via continuous
  /// auto-focus/3A), when focused to a specific point (via
  /// ``CameraController/focus(at:options:)``), or when locked to
  /// a specific lens-position value (via ``CameraController/lockFocus(at:)``).
  public var lensPosition: Double {
    return Double(captureDevice.lensPosition)
  }

  /// The current exposure duration, in seconds, including values selected by automatic exposure.
  ///
  /// The ``CameraController/exposureDuration`` value changes over time (via
  /// continuous auto-focus/3A), when focused to a specific point (via
  /// ``CameraController/focus(at:options:)``), or when locked to
  /// a specific duration/ISO value (via ``CameraController/lockExposure(duration:iso:)``).
  public var exposureDuration: Double {
    return captureDevice.exposureDuration.seconds
  }

  /// The active maximum exposure duration, in seconds.
  public var activeMaxExposureDuration: Double {
    return captureDevice.activeMaxExposureDuration.seconds
  }

  /// The current exposure compensation bias, in EV units.
  ///
  /// A positive value (like `1`) means over-exposed ("brighter"),
  /// whereas a negative value (like `-1`) means under-exposed ("darker").
  /// The default exposure bias is `0`.
  ///
  /// You can set exposure bias to a supported value via
  /// ``CameraController/setExposureBias(_:)``.
  public var exposureBias: Double {
    return Double(captureDevice.exposureTargetBias)
  }

  /// The current sensor sensitivity, including values selected by automatic exposure.
  ///
  /// The ``CameraController/iso`` value changes over time (via continuous
  /// auto-focus/3A), when focused to a specific point (via
  /// ``CameraController/focus(at:options:)``), or when locked to
  /// a specific duration/ISO value (via ``CameraController/lockExposure(duration:iso:)``).
  public var iso: Double {
    return Double(captureDevice.iso)
  }

  /// Configures this ``CameraController`` with the
  /// given ``CameraControllerConfiguration``.
  ///
  /// Like a diff-map, setting a value inside the `config`
  /// object to `nil`, causes the prop to be left at whatever
  /// its current value is.
  public func configure(_ configuration: CameraControllerConfiguration) async throws {
    return try await captureDevice.withLock(queue) {
      let device = self.captureDevice

      // Low-light boost
      if let enableLowLightBoost = configuration.isLowLightBoostEnabled {
        guard device.isLowLightBoostSupported else {
          throw CameraControlError.unsupportedFeature(.lowLightBoost)
        }
        device.automaticallyEnablesLowLightBoostWhenAvailable = enableLowLightBoost
      }

      // Smooth autofocus
      if let enableSmoothAutoFocus = configuration.isSmoothAutoFocusEnabled {
        guard device.isSmoothAutoFocusSupported else {
          throw CameraControlError.unsupportedFeature(.smoothAutoFocus)
        }
        device.isSmoothAutoFocusEnabled = enableSmoothAutoFocus
      }

      // Distortion correction
      if let isDistortionCorrectionEnabled = configuration.isDistortionCorrectionEnabled {
        guard device.isGeometricDistortionCorrectionSupported else {
          throw CameraControlError.unsupportedFeature(.distortionCorrection)
        }
        device.isGeometricDistortionCorrectionEnabled = isDistortionCorrectionEnabled
      }
    }
  }

  /// Sets the Camera's zoom to the
  /// specified ``CameraController/zoom`` value.
  ///
  /// - Throws: If the ``CameraDevice`` does not support the given ``CameraController/zoom``
  /// value. See ``CameraDevice/minZoom`` / ``CameraDevice/maxZoom``
  ///
  /// ```swift
  /// try await controller.setZoom(2)
  /// ```
  public func setZoom(_ zoom: Double) async throws {
    return try await captureDevice.withLock(queue) {
      // 1. Ensure zoom is within valid range
      let device = self.captureDevice
      guard zoom >= device.minAvailableVideoZoomFactor && zoom <= device.maxAvailableVideoZoomFactor
      else {
        throw CameraControlError.valueOutOfRange(
          parameter: .zoom, value: zoom, allowed: device.minAvailableVideoZoomFactor...device.maxAvailableVideoZoomFactor)
      }
      // 2. Clamp zoom to the active format's max zoom (might be slightly smaller than device max zoom)
      let clampedForFormat = min(zoom, device.activeFormat.videoMaxZoomFactor)
      // 3. Apply zoom
      device.videoZoomFactor = clampedForFormat
    }
  }

  /// Focuses the Camera pipeline to the specified ``MeteringPoint``,
  /// using the specified ``MeteringMode``s.
  ///
  /// By default, all metering modes that are supported on this device are enabled -
  /// ideally that's ``MeteringMode/ae``, ``MeteringMode/af`` and
  /// ``MeteringMode/awb`` - also known as 3A.
  ///
  /// After the metering operation has settled, the Camera pipeline either keeps
  /// the specified ``MeteringPoint`` continuously focused even if
  /// the scene at the specific point changes (``SceneAdaptiveness/continuous``),
  /// or locks the focus/exposure/white-balance values in-place (``SceneAdaptiveness/locked``).
  /// You can adjust this behaviour via ``FocusOptions/adaptiveness``.
  ///
  /// - Parameter point: The ``MeteringPoint`` to focus to.
  /// - Parameter options: Options for this focus operation.
  ///
  /// - Throws: If the ``CameraController/device`` does not support metering (see ``CameraDevice/supportsFocusMetering``)
  /// - Throws: If ``MeteringMode/ae`` is enabled, but the ``CameraController/device`` does
  /// not support metering exposure (see ``CameraDevice/supportsExposureMetering``)
  /// - Throws: If ``MeteringMode/af`` is enabled, but the ``CameraController/device`` does
  /// not support metering focus (see ``CameraDevice/supportsFocusMetering``)
  /// - Throws: If ``MeteringMode/awb`` is enabled, but the ``CameraController/device`` does
  /// not support metering white-balance (see ``CameraDevice/supportsWhiteBalanceMetering``)
  ///
  /// ```swift
  /// let point = MeteringPoint(location: CGPoint(x: 0.5, y: 0.5))
  /// try await controller.focus(
  ///   at: point,
  ///   options: FocusOptions(responsiveness: .steady)
  /// )
  ///
  /// // Lock focus at a tap until it is reset.
  /// let tapPoint = try previewView.meteringPoint(at: CGPoint(x: tapX, y: tapY))
  /// try await controller.focus(
  ///   at: tapPoint,
  ///   options: FocusOptions(
  ///     responsiveness: .snappy,
  ///     adaptiveness: .locked,
  ///     reset: .never
  ///   )
  /// )
  /// ```
  ///
  /// This method returns once focusing has fully settled, or throws if focusing times out or is canceled. Calling this method again or ``CameraController/resetFocus()`` cancels the previous operation.
  ///
  /// An omitted ``FocusOptions/reset`` resets metering after 5 seconds. Use ``FocusReset/never`` to keep the selected behavior until you reset it.
  public func focus(
    at point: MeteringPoint,
    options: FocusOptions = .init()
  ) async throws {
    return try await captureDevice.withLock(queue) { resolve, reject in
      try point.validate()
      try options.reset.validate()
      let responsiveness = options.responsiveness
      let adaptiveness = options.adaptiveness
      let reset = options.reset
      let modes = options.modes ?? self.supportedMeteringModes
      guard !modes.isEmpty else {
        throw CameraControlError.emptyMeteringModes
      }

      // Cancel previous tasks
      self.activeMeteringTask?.cancel()
      self.activeMeteringTask = nil

      // Create a new MeteringTask and start the desired metering operations
      let task = MeteringTask(
        device: self.captureDevice,
        adaptiveness: adaptiveness,
        autoReset: reset.toAutoReset(),
        on: self.queue)
      // AE
      if modes.contains(.ae) {
        try task.startMeteringAE(
          to: point.location,
          responsiveness: responsiveness)
      }
      // AF
      if modes.contains(.af) {
        try task.startMeteringAF(
          to: point.location,
          responsiveness: responsiveness)
      }
      // AWB
      if modes.contains(.awb) {
        try task.startMeteringAWB(responsiveness: responsiveness)
      }

      // Start listening to updates
      task.startListening(
        onComplete: resolve,
        onError: reject
      )
      self.activeMeteringTask = task

    }
  }

  /// Get a list of all [MeteringMode]s that are supported on this device.
  private var supportedMeteringModes: [MeteringMode] {
    var modes: [MeteringMode] = []
    if device.supportsExposureMetering {
      modes.append(.ae)
    }
    if device.supportsFocusMetering {
      modes.append(.af)
    }
    // White Balance adjusting is not point-based, but it still requires a supported auto mode.
    if device.supportsWhiteBalanceMetering {
      modes.append(.awb)
    }
    return modes
  }

  /// Cancels any current focus operations from ``CameraController/focus(at:options:)``,
  /// resets back all 3A focus modes to continuously auto-focus if they
  /// have been previously locked (e.g. via ``CameraController/lockFocus(at:)`` or
  /// ``CameraController/lockCurrentFocus()``, and similar), and
  /// resets the focus point of interest to be in the center.
  ///
  /// ```swift
  /// try await controller.resetFocus()
  /// ```
  public func resetFocus() async throws {
    return try await captureDevice.withLock(queue) {
      // cancel an ongoing focus operation
      self.activeMeteringTask?.cancel()
      self.activeMeteringTask = nil

      logger.info("Resetting focus...")
      let device = self.captureDevice
      // reset AF to center + continuous tracking
      if device.isFocusPointOfInterestSupported {
        device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
      }
      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
      // reset AE to center + continuous tracking
      if device.isExposurePointOfInterestSupported {
        device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
      }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
      // reset AWB to continuous tracking
      if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
        device.whiteBalanceMode = .continuousAutoWhiteBalance
      }
    }
  }

  /// Adds a listener to be fired everytime the subject area
  /// substantially changes - e.g. when the user pans away
  /// from a scene previously in focus.
  ///
  /// Retain the returned ``ObservationToken`` while observing. Cancel or release it
  /// to stop receiving subject-area-change events. Multiple
  /// subscriptions can coexist; the device stops monitoring
  /// subject-area changes only once the last subscription is
  /// removed.
  ///
  /// When manually locking focus (e.g. via
  /// ``CameraController/focus(at:options:)`` with ``FocusOptions/adaptiveness`` set to ``SceneAdaptiveness/locked``,
  /// ``CameraController/lockFocus(at:)`` (or similar), or
  /// ``CameraController/lockCurrentFocus()`` (or similar)),
  /// it is useful to listen for subject area changes, to reset focus
  /// again via ``CameraController/resetFocus()``.
  ///
  /// ```swift
  /// try await controller.lockCurrentExposure()
  /// try await controller.lockCurrentFocus()
  /// try await controller.lockCurrentWhiteBalance()
  /// let token = controller.observeSubjectAreaChanges {
  ///   Task {
  ///     do { try await controller.resetFocus() }
  ///     catch { print(error.localizedDescription) }
  ///   }
  /// }
  /// // Later, to stop listening:
  /// token.cancel()
  /// ```
  ///
  /// The listener runs on the device's subject-area notification delivery thread. Dispatch UIKit work to the main queue.
  public func observeSubjectAreaChanges(_ onSubjectAreaChanged: @escaping () -> Void) -> ObservationToken {
    return SubjectAreaMonitor.addObserver(
      device: captureDevice,
      onSubjectAreaDidChange: onSubjectAreaChanged)
  }

  /// Sets the device's native torch mode.
  ///
  /// Use `.auto` to let the device illuminate dark scenes when it supports automatic torch control.
  /// Setting `.off` succeeds when the device has no torch.
  /// - Throws: If the device does not support the requested mode.
  public func setTorchMode(_ mode: AVCaptureDevice.TorchMode) async throws {
    return try await captureDevice.withLock(queue) {
      let device = self.captureDevice
      if !device.hasTorch && mode == .off { return }
      guard device.isTorchModeSupported(mode) else {
        throw CameraControlError.unsupportedFeature(.torch)
      }
      device.torchMode = mode
    }
  }

  /// Turns the torch on at the given brightness level.
  ///
  /// - Parameter level: A finite value greater than `0` and no greater than `1`, or `AVCaptureDevice.maxAvailableTorchLevel` to use the currently available maximum.
  /// - Throws: If the level is outside that range, the device has no torch, or AVFoundation cannot enable it.
  ///
  /// ```swift
  /// try await controller.setTorchModeOn(level: 0.5)
  /// ```
  public func setTorchModeOn(level: Float) async throws {
    try Self.validateTorchLevel(level)
    return try await captureDevice.withLock(queue) {
      guard self.captureDevice.isTorchModeSupported(.on) else {
        throw CameraControlError.unsupportedFeature(.torch)
      }
      try self.captureDevice.setTorchModeOn(level: level)
    }
  }

  /// Starts animating the Camera's zoom
  /// to the specified ``CameraController/zoom`` value,
  /// at the specified `rate`.
  ///
  /// - Throws: If the ``CameraDevice`` does not support the given ``CameraController/zoom``
  /// value. See ``CameraDevice/minZoom`` / ``CameraDevice/maxZoom``
  ///
  /// ```swift
  /// try await controller.rampZoom(to: 2, rate: 3)
  /// ```
  ///
  /// Returns when the device finishes ramping, including when the ramp is canceled. The target zoom must be within the controller's available zoom range, and the rate must be positive.
  public func rampZoom(to zoom: Double, rate: Double) async throws {
    return try await captureDevice.withLock(queue) { completion in
      let allowed = Double(self.captureDevice.minAvailableVideoZoomFactor)...Double(self.captureDevice.maxAvailableVideoZoomFactor)
      guard zoom.isFinite && allowed.contains(zoom) else {
        throw CameraControlError.valueOutOfRange(parameter: .zoom, value: zoom, allowed: allowed)
      }
      guard rate.isFinite && rate > 0 && rate <= Double(Float.greatestFiniteMagnitude) else {
        throw CameraControlError.invalidZoomRampRate(rate)
      }
      if self.captureDevice.videoZoomFactor == zoom {
        // We are already exactly on our target value
        completion()
        return
      }

      var observation: NSKeyValueObservation?
      observation = self.captureDevice.observe(
        \.isRampingVideoZoom,
        options: [.old, .new],
        changeHandler: { _, change in
          if change.oldValue == true && change.newValue == false {
            observation?.invalidate()
            observation = nil
            completion()
          }
        })

      self.captureDevice.ramp(toVideoZoomFactor: zoom, withRate: Float(rate))
    }
  }

  /// Cancels any zoom animations previously
  /// started with ``CameraController/rampZoom(to:rate:)``.
  public func cancelZoomRamp() async throws {
    return try await captureDevice.withLock(queue) {
      self.captureDevice.cancelVideoZoomRamp()
    }
  }

  /// Sets the ``CameraController/exposureBias`` to the given
  /// `exposure` bias value.
  ///
  /// A positive value (like `1`) means over-exposed ("brighter"),
  /// whereas a negative value (like `-1`) means under-exposed ("darker").
  /// The default exposure bias is `0`.
  ///
  /// - Throws: If the ``CameraController/device`` does not support this `exposure` bias value (see ``CameraDevice/minExposureBias`` / ``CameraDevice/maxExposureBias``)
  ///
  /// ```swift
  /// try await controller.setExposureBias(1)
  /// ```
  public func setExposureBias(_ exposure: Double) async throws {
    return try await captureDevice.withLock(queue) { completion in
      // 1. Ensure exposureBias is within range
      let device = self.captureDevice
      let exposure = Float(exposure)
      guard exposure >= device.minExposureTargetBias && exposure <= device.maxExposureTargetBias else {
        throw CameraControlError.valueOutOfRange(
          parameter: .exposureBias, value: Double(exposure), allowed: Double(device.minExposureTargetBias)...Double(device.maxExposureTargetBias))
      }

      // 2. Set Exposure Bias
      device.setExposureTargetBias(Float(exposure)) { _ in
        // 3. Once exposure is set, complete the operation
        completion()
      }
    }
  }

  /// Locks the focus at the specified ``CameraController/lensPosition``.
  ///
  /// - Parameter lensPosition: The position of the Camera lens, from `0.0` (closest) to `1.0` (furthest).
  ///
  /// - Throws: If ``CameraController/lensPosition`` is outside of `0.0` ... `1.0`.
  /// - Throws: If the ``CameraController/device`` does not support manual focus locking (see ``CameraDevice/supportsCustomLensPosition``)
  public func lockFocus(at lensPosition: Double) async throws {
    return try await captureDevice.withLock(queue) { completion in
      guard self.captureDevice.isLockingFocusWithCustomLensPositionSupported else {
        throw CameraControlError.unsupportedFeature(.focusLock)
      }
      // 1. Ensure values are within valid range
      guard lensPosition >= 0 && lensPosition <= 1 else {
        throw CameraControlError.valueOutOfRange(parameter: .lensPosition, value: lensPosition, allowed: 0...1)
      }

      // 2. Lock Focus
      self.captureDevice.setFocusModeLocked(lensPosition: Float(lensPosition)) { _ in
        // 3. Once it locked, complete the operation
        completion()
      }
    }
  }

  /// Locks the current focus values.
  ///
  /// You can read the current focus values via
  /// ``CameraController/lensPosition``.
  /// - Throws: If the device does not support locking focus -
  /// see ``CameraDevice/supportsFocusLocking``
  ///
  /// To reset focus again to be automatically adjusted by the Camera,
  /// use ``CameraController/resetFocus()``.
  ///
  /// ```swift
  /// try await controller.lockCurrentFocus()
  /// ```
  public func lockCurrentFocus() async throws {
    return try await captureDevice.withLock(queue) { completion in
      guard self.captureDevice.isFocusModeSupported(.locked) else {
        throw CameraControlError.unsupportedFeature(.focusLock)
      }
      self.captureDevice.setFocusModeLocked(lensPosition: AVCaptureDevice.currentLensPosition) {
        _ in
        completion()
      }
    }
  }

  /// Represents the minimum value for the ``CameraController/lockExposure(duration:iso:)``
  /// parameter in ``CameraController/lockExposure(duration:iso:)`` for the active format.
  public var minExposureDuration: Double {
    return captureDevice.activeFormat.minExposureDuration.seconds
  }

  /// Represents the maximum value for the ``CameraController/lockExposure(duration:iso:)``
  /// parameter in ``CameraController/lockExposure(duration:iso:)`` for the active format.
  public var maxExposureDuration: Double {
    return captureDevice.activeFormat.maxExposureDuration.seconds
  }

  /// Represents the minimum value for the ``CameraController/lockExposure(duration:iso:)``
  /// parameter in ``CameraController/lockExposure(duration:iso:)`` for the active format.
  public var minISO: Double {
    return Double(captureDevice.activeFormat.minISO)
  }

  /// Represents the maximum value for the ``CameraController/lockExposure(duration:iso:)``
  /// parameter in ``CameraController/lockExposure(duration:iso:)`` for the active format.
  public var maxISO: Double {
    return Double(captureDevice.activeFormat.maxISO)
  }

  /// Locks the exposure at the specified `duration`
  /// and ``CameraController/iso`` value.
  ///
  /// - Parameter duration: The duration in seconds a single shutter is timed at. It must be a value between ``CameraController/minExposureDuration`` and ``CameraController/maxExposureDuration``.
  /// - Parameter iso: The ISO value for the Camera. It must be a value between ``CameraController/minISO`` and ``CameraController/maxISO``.
  ///
  /// - Throws: If `duration` or ``CameraController/iso`` are not valid values.
  /// - Throws: If the ``CameraController/device`` does not support manual exposure locking (see ``CameraDevice/supportsCustomExposure``)
  public func lockExposure(duration: Double, iso: Double) async throws {
    return try await captureDevice.withLock(queue) { completion in
      guard self.captureDevice.isExposureModeSupported(.custom) else {
        throw CameraControlError.unsupportedFeature(.exposureLock)
      }
      let device = self.captureDevice
      guard device.isExposureModeSupported(.custom) else {
        throw CameraControlError.unsupportedFeature(.exposureLock)
      }
      // 1. Ensure values are within valid range
      guard
        duration >= device.activeFormat.minExposureDuration.seconds
          && duration <= device.activeFormat.maxExposureDuration.seconds
      else {
        throw CameraControlError.valueOutOfRange(
          parameter: .exposureDuration, value: duration,
          allowed: device.activeFormat.minExposureDuration.seconds...device.activeFormat.maxExposureDuration.seconds)
      }
      let iso = Float(iso)
      guard iso >= device.activeFormat.minISO && iso <= device.activeFormat.maxISO else {
        throw CameraControlError.valueOutOfRange(
          parameter: .iso, value: Double(iso), allowed: Double(device.activeFormat.minISO)...Double(device.activeFormat.maxISO))
      }

      // 2. Set the Exposure Duration/ISO
      let time = CMTime(seconds: duration, preferredTimescale: 1_000_000)
      device.setExposureModeCustom(duration: time, iso: iso) { _ in
        // 3. Once exposure is set, complete the operation
        completion()
      }
    }
  }

  /// Locks the current exposure values.
  ///
  /// You can read the current exposure values via
  /// ``CameraController/exposureDuration`` and ``CameraController/iso``.
  /// - Throws: If the device does not support locking exposure -
  /// see ``CameraDevice/supportsExposureLocking``
  ///
  /// To reset exposure again to be automatically adjusted by the Camera,
  /// use ``CameraController/resetFocus()``.
  ///
  /// ```swift
  /// try await controller.lockCurrentExposure()
  /// ```
  public func lockCurrentExposure() async throws {
    return try await captureDevice.withLock(queue) {
      guard self.captureDevice.isExposureModeSupported(.locked) else {
        throw CameraControlError.unsupportedFeature(.exposureLock)
      }
      self.captureDevice.exposureMode = .locked
    }
  }

  /// Converts native temperature and tint values into gains for this device.
  ///
  /// Clamp each returned gain to `1...device.maxWhiteBalanceGain` before locking white balance.
  public func whiteBalanceGains(
    for whiteBalanceTemperatureAndTint: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues
  ) -> AVCaptureDevice.WhiteBalanceGains {
    return captureDevice.deviceWhiteBalanceGains(for: whiteBalanceTemperatureAndTint)
  }

  /// Locks the white-balance at the specified ``CameraController/whiteBalanceGains``
  /// value.
  ///
  /// - Parameter whiteBalanceGains: The native red, green, and blue channel gains.
  /// Each channel's value must be within `1` and the current ``CameraController/device``'s
  /// ``CameraDevice/maxWhiteBalanceGain`` value.
  ///
  /// - Throws: If one of the channels in ``CameraController/whiteBalanceGains`` is out-of-range.
  /// - Throws: If the ``CameraController/device`` does not support manual white-balance locking (see ``CameraDevice/supportsCustomWhiteBalanceGains``)
  public func lockWhiteBalance(gains whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains) async throws {
    return try await captureDevice.withLock(queue) { completion in
      guard self.captureDevice.isLockingWhiteBalanceWithCustomDeviceGainsSupported else {
        throw CameraControlError.unsupportedFeature(.whiteBalanceLock)
      }
      // 1. Ensure values are within valid range
      let device = self.captureDevice
      guard device.isLockingWhiteBalanceWithCustomDeviceGainsSupported else {
        throw CameraControlError.unsupportedFeature(.whiteBalanceLock)
      }
      let redGain = whiteBalanceGains.redGain
      let greenGain = whiteBalanceGains.greenGain
      let blueGain = whiteBalanceGains.blueGain
      guard redGain >= 1 && redGain <= device.maxWhiteBalanceGain else {
        throw CameraControlError.valueOutOfRange(parameter: .redGain, value: Double(redGain), allowed: 1...Double(device.maxWhiteBalanceGain))
      }
      guard greenGain >= 1 && greenGain <= device.maxWhiteBalanceGain else {
        throw CameraControlError.valueOutOfRange(parameter: .greenGain, value: Double(greenGain), allowed: 1...Double(device.maxWhiteBalanceGain))
      }
      guard blueGain >= 1 && blueGain <= device.maxWhiteBalanceGain else {
        throw CameraControlError.valueOutOfRange(parameter: .blueGain, value: Double(blueGain), allowed: 1...Double(device.maxWhiteBalanceGain))
      }

      // 2. Lock White Balance Gains
      let values = AVCaptureDevice.WhiteBalanceGains(
        redGain: redGain,
        greenGain: greenGain,
        blueGain: blueGain)
      device.setWhiteBalanceModeLocked(with: values) { _ in
        // 3. Once White Balance is locked, complete the operation
        completion()
      }
    }
  }

  /// Locks the current white-balance values.
  ///
  /// You can read the current white-balance values via
  /// ``CameraController/whiteBalanceGains``.
  /// - Throws: If the device does not support locking white balance -
  /// see ``CameraDevice/supportsWhiteBalanceLocking``
  ///
  /// To reset white-balance again to be automatically adjusted by the Camera,
  /// use ``CameraController/resetFocus()``.
  ///
  /// ```swift
  /// try await controller.lockCurrentWhiteBalance()
  /// ```
  public func lockCurrentWhiteBalance() async throws {
    return try await captureDevice.withLock(queue) { completion in
      guard self.captureDevice.isWhiteBalanceModeSupported(.locked) else {
        throw CameraControlError.unsupportedFeature(.whiteBalanceLock)
      }
      self.captureDevice.setWhiteBalanceModeLocked(with: AVCaptureDevice.currentWhiteBalanceGains) {
        _ in
        completion()
      }
    }
  }
}
