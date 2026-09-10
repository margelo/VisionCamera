///
/// CameraDeviceFactory.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``CameraDeviceFactory`` allows getting ``CameraDevice``s, listening to device changes, and querying preferred Cameras.
public final class CameraDeviceFactory {
  /// Creates a device discovery session for the available Camera device types.
  public init() {
    self.discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: AVCaptureDevice.DeviceType.all,
      mediaType: nil,
      position: .unspecified)
  }

  /// The underlying AVFoundation discovery session.
  public let discoverySession: AVCaptureDevice.DiscoverySession
  /// Get a list of all ``CameraDevice``s on this platform.
  ///
  /// This list may change as Cameras get plugged in/out, for example external Cameras via USB/UVC, or become available/unavailable, for example Continuity Cameras.
  public var cameraDevices: [CameraDevice] {
    return discoverySession.devices.map { CameraDevice(device: $0) }
  }

  /// A list of all ``CameraDevice`` combinations that are supported
  /// in Multi-Cam ``CameraSession``s.
  ///
  /// This list always contains a subset of ``CameraDeviceFactory/cameraDevices``, often
  /// less.
  ///
  /// Each inner array contains one or more logical ``CameraDevice``s.
  /// On iOS, a combination can contain a single virtual ``CameraDevice``
  /// such as a Dual- or Triple-Camera, because that device is backed by multiple
  /// physical Cameras. You can inspect those physical Cameras via
  /// ``CameraDevice/physicalDevices``, but pass the
  /// returned ``CameraDevice``s directly to
  /// ``CameraSession/configure(connections:config:)``.
  ///
  /// If you need multiple independent inputs, choose a combination with at least
  /// two ``CameraDevice``s.
  ///
  /// For example, on many platforms only a ``CameraPosition/front``
  /// and a ``CameraPosition/back`` ``CameraDevice`` are
  /// supported to be used in a Multi-Cam ``CameraSession`` - in this case,
  /// the returned 2D Array looks something like this:
  ///
  /// Two ``CameraPosition/back``-, or two ``CameraPosition/front``
  /// ``CameraDevice``s are often not supported together in a Multi-Cam
  /// ``CameraSession``.
  ///
  /// When creating a Multi-Cam ``CameraSession``, you must ensure
  /// that you are using Device combinations that are actually supported
  /// on the platform, otherwise the session might fail to configure.
  ///
  /// If the platform does not support Multi-Cam ``CameraSession``s,
  /// an empty array (`[]`) will be returned.
  ///
  /// See ``VisionCamera/supportsMultiCamSessions``
  ///
  /// ```swift
  /// let camera = VisionCamera()
  /// let factory = camera.createDeviceFactory()
  /// if camera.supportsMultiCamSessions,
  ///    let devices = factory.supportedMultiCamDeviceCombinations.first {
  ///   let connections = devices.map { device in
  ///     CameraSessionConnection(
  ///       input: .device(device),
  ///       outputs: [CameraOutputConfiguration(output: camera.createPreviewOutput())]
  ///     )
  ///   }
  ///   let session = try camera.createCameraSession(enableMultiCam: true)
  ///   let controllers = try await session.configure(connections: connections)
  ///   await session.start()
  /// }
  /// ```
  public var supportedMultiCamDeviceCombinations: [[CameraDevice]] {
    return discoverySession.supportedMultiCamDeviceSets.map { devices in
      return devices.map { CameraDevice(device: $0) }
    }
  }

  /// Get or set the user's default preferred camera device.
  /// Setting a device here will persist the preference between apps.
  ///
  /// Requires iOS 17 or later. On earlier versions, reading returns `nil` and setting has no effect.
  public var userPreferredCamera: (CameraDevice)? {
    get {
      guard #available(iOS 17.0, *) else {
        return nil
      }
      guard let device = AVCaptureDevice.userPreferredCamera else {
        return nil
      }
      return CameraDevice(device: device)
    }
    set {
      guard #available(iOS 17.0, *) else {
        return
      }
      AVCaptureDevice.userPreferredCamera = newValue?.device
    }
  }

  /// Add a listener to be called whenever the
  /// available ``CameraDeviceFactory/cameraDevices`` change,
  /// for example when an external USB Camera
  /// gets plugged in- or out- of the Device.
  ///
  /// The callback runs on AVFoundation's observation delivery thread. Call ``ListenerSubscription/remove`` to stop receiving updates; move UIKit work to the main actor.
  public func addOnCameraDevicesChangedListener(listener: @escaping ([CameraDevice]) -> Void)
    -> ListenerSubscription
  {
    // 1. Attach a listener using KVO
    let observation = discoverySession.observe(\.devices, options: [.old, .new]) { _, change in
      guard let newDevices = change.newValue else { return }
      logger.info("Devices changed! \(change.oldValue?.count ?? 0) -> \(newDevices.count)")
      let devices = newDevices.map { CameraDevice(device: $0) }
      listener(devices)
    }

    // 2. Return a remove function that removes the listener via KVO
    return ListenerSubscription(remove: {
      observation.invalidate()
    })
  }

  /// Get the ``CameraDevice`` with the given unique
  /// `id`.
  ///
  /// If no device with the given `id` is found,
  /// this method returns `nil`.
  public func getCameraForId(id: String) -> (CameraDevice)? {
    guard let device = AVCaptureDevice(uniqueID: id) else {
      return nil
    }
    return CameraDevice(device: device)
  }

  /// Get the platform's default ``CameraDevice``
  /// at the given ``TargetCameraPosition``.
  public func getDefaultCamera(position: TargetCameraPosition) -> (CameraDevice)? {
    guard let device = AVCaptureDevice.default(for: position) else {
      return nil
    }
    return CameraDevice(device: device)
  }

}
