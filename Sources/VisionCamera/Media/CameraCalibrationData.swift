// Copyright © 2025 Marc Rousavy @ Margelo

//
//  CameraCalibrationData.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 29.10.25.
//

import AVFoundation
import Foundation

public final class CameraCalibrationData {
  public let calibrationData: AVCameraCalibrationData

  public init(calibrationData: AVCameraCalibrationData) {
    self.calibrationData = calibrationData
  }

  public var pixelSize: Double {
    return Double(calibrationData.pixelSize)
  }

  public var intrinsicMatrixReferenceDimensions: Size {
    let cgSize = calibrationData.intrinsicMatrixReferenceDimensions
    return Size(cgSize)
  }

  public var lensDistortionCenter: Point {
    let cgPoint = calibrationData.lensDistortionCenter
    return Point(cgPoint)
  }

  public private(set) lazy var cameraIntrinsicMatrix: [Double] = {
    return calibrationData.intrinsicMatrix.toDoubleArray()
  }()

  public private(set) lazy var cameraExtrinsicsMatrix: [Double] = {
    return calibrationData.extrinsicMatrix.toDoubleArray()
  }()
}
