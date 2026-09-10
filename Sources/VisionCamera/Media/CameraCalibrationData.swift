// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreGraphics
import simd

/// Per-sample Camera calibration data for distortion correction and 3D projection.
///
/// The value retains AVFoundation's calibration data. Matrices use native SIMD storage rather than
/// flattened arrays, and dimensions and points use Core Graphics coordinates.
public struct CameraCalibrationData {
  /// The retained native calibration data, including lens-distortion lookup tables.
  public let calibrationData: AVCameraCalibrationData

  /// Creates a value retaining the native calibration data.
  public init(calibrationData: AVCameraCalibrationData) {
    self.calibrationData = calibrationData
  }

  /// The size of one pixel at the reference dimensions, in millimeters.
  public var pixelSize: Float { calibrationData.pixelSize }
  /// The image dimensions used to calculate the intrinsic matrix and distortion center.
  public var referenceDimensions: CGSize { calibrationData.intrinsicMatrixReferenceDimensions }
  /// The lens-distortion center, measured from the reference image's top-left corner.
  public var distortionCenter: CGPoint { calibrationData.lensDistortionCenter }
  /// The column-major matrix mapping 3D Camera coordinates into 2D pixel coordinates.
  ///
  /// The first two diagonal elements contain focal lengths; the third column contains the principal point.
  public var intrinsicMatrix: simd_float3x3 { calibrationData.intrinsicMatrix }
  /// The column-major matrix mapping world coordinates into Camera coordinates.
  ///
  /// The first three columns describe rotation and the fourth contains translation in millimeters.
  public var extrinsicMatrix: simd_float4x3 { calibrationData.extrinsicMatrix }
}
