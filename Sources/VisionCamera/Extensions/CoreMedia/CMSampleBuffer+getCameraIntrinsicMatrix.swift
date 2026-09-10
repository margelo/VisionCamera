//
//  CMSampleBuffer+getCameraIntrinsicMatrix.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 23.01.26.
//

import AVFoundation

extension CMSampleBuffer {
  func getCameraIntrinsicMatrix() -> simd_float3x3? {
    guard let matrixAttachment = self.attachments[.cameraIntrinsicMatrix],
      let matrixData = matrixAttachment.value as? Data,
      matrixData.count >= MemoryLayout<simd_float3x3>.stride
    else {
      return nil
    }
    let matrix: simd_float3x3 = matrixData.withUnsafeBytes { buffer in
      var matrix = matrix_identity_float3x3
      withUnsafeMutableBytes(of: &matrix) { destination in
        destination.copyBytes(from: buffer.prefix(destination.count))
      }
      return matrix
    }
    return matrix
  }
}
