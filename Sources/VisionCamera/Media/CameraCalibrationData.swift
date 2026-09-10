// Copyright © 2025 Marc Rousavy @ Margelo

//
//  CameraCalibrationData.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 29.10.25.
//

import AVFoundation
import Foundation

/// Camera Calibration Data is per-frame data
/// used to counter-apply any transformations applied
/// by the Camera/ISP.
///
/// It can be useful to undo any distortion correction,
/// or compute scenery in 3D space.
///
/// See ``Depth/cameraCalibrationData``
/// See ``Photo/calibrationData``
public final class CameraCalibrationData {
  /// The retained native AVFoundation calibration data.
  public let calibrationData: AVCameraCalibrationData

  /// Creates a CameraCalibrationData that retains the given native AVFoundation calibration data.
  public init(calibrationData: AVCameraCalibrationData) {
    self.calibrationData = calibrationData
  }

  /// The size of one pixel at ``CameraCalibrationData/intrinsicMatrixReferenceDimensions`` in millimeters.
  public var pixelSize: Double {
    return Double(calibrationData.pixelSize)
  }

  /// The reference frame dimensions used in calculating a camera's principal point.
  public var intrinsicMatrixReferenceDimensions: Size {
    let cgSize = calibrationData.intrinsicMatrixReferenceDimensions
    return Size(cgSize)
  }

  /// A ``Point`` describing the offset of the lens' distortion center
  /// from the top left in ``CameraCalibrationData/intrinsicMatrixReferenceDimensions``.
  public var lensDistortionCenter: Point {
    let cgPoint = calibrationData.lensDistortionCenter
    return Point(cgPoint)
  }

  /// Gets the Camera intrinsic matrix, which maps 3D Camera coordinates
  /// to 2D Pixel coordinates.
  ///
  /// The returned SIMD value has three columns and three rows.
  /// Its origin is the top-left of the Frame.
  ///
  /// ```
  /// K = [ fx   0  cx ]
  ///     [  0  fy  cy ]
  ///     [  0   0   1 ]
  /// ```
  /// - `fx`, `fy`: focal length in pixels
  /// - `cx`, `cy`: principal point in pixels
  ///
  /// ```swift
  /// let matrix = calibrationData.cameraIntrinsicMatrix
  /// let fx = matrix[0, 0]
  /// let fy = matrix[1, 1]
  /// ```
  public var cameraIntrinsicMatrix: simd_float3x3 { calibrationData.intrinsicMatrix }

  /// Gets the Camera extrinsic matrix, which maps world space
  /// to camera space.
  ///
  /// The returned SIMD value has four columns and three rows.
  ///
  /// ```
  /// K = [ r11 r12 r13 tx ]
  ///     [ r21 r22 r23 ty ]
  ///     [ r31 r32 r33 tz ]
  /// ```
  /// - `r`: Rotation/orientation
  /// - `t`: Translation/position (in millimeters)
  public var cameraExtrinsicsMatrix: simd_float4x3 { calibrationData.extrinsicMatrix }
}
