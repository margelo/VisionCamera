// Copyright © 2025 Marc Rousavy @ Margelo

import CoreLocation

public struct CapturePhotoSettings {
  public var flashMode: FlashMode?
  public var enableShutterSound: Bool?
  public var enableDepthData: Bool?
  public var enableRedEyeReduction: Bool?
  public var enableCameraCalibrationDataDelivery: Bool?
  public var enableDistortionCorrection: Bool?
  public var enableVirtualDeviceFusion: Bool?
  public var location: CLLocation?

  public init(
    flashMode: FlashMode? = nil,
    enableShutterSound: Bool? = nil,
    enableDepthData: Bool? = nil,
    enableRedEyeReduction: Bool? = nil,
    enableCameraCalibrationDataDelivery: Bool? = nil,
    enableDistortionCorrection: Bool? = nil,
    enableVirtualDeviceFusion: Bool? = nil,
    location: CLLocation? = nil
  ) {
    self.flashMode = flashMode
    self.enableShutterSound = enableShutterSound
    self.enableDepthData = enableDepthData
    self.enableRedEyeReduction = enableRedEyeReduction
    self.enableCameraCalibrationDataDelivery = enableCameraCalibrationDataDelivery
    self.enableDistortionCorrection = enableDistortionCorrection
    self.enableVirtualDeviceFusion = enableVirtualDeviceFusion
    self.location = location
  }
}
