///
/// CameraDeviceFactory.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraDeviceFactory {
  public init() {
    self.discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: AVCaptureDevice.DeviceType.all,
      mediaType: nil,
      position: .unspecified)
  }

  public let discoverySession: AVCaptureDevice.DiscoverySession
  public var cameraDevices: [CameraDevice] {
    return discoverySession.devices.map { CameraDevice(device: $0) }
  }

  public var supportedMultiCamDeviceCombinations: [[CameraDevice]] {
    return discoverySession.supportedMultiCamDeviceSets.map { devices in
      return devices.map { CameraDevice(device: $0) }
    }
  }

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

  public func getCameraForId(id: String) -> (CameraDevice)? {
    guard let device = AVCaptureDevice(uniqueID: id) else {
      return nil
    }
    return CameraDevice(device: device)
  }

  public func getDefaultCamera(position: TargetCameraPosition) -> (CameraDevice)? {
    guard let device = AVCaptureDevice.default(for: position) else {
      return nil
    }
    return CameraDevice(device: device)
  }

}
