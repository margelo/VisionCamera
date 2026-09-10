///
/// AV+DepthPixelFormat.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension DepthPixelFormat {
  init(osType: OSType) {
    switch osType {
    case kCVPixelFormatType_DepthFloat16:
      self = .depth16Bit
    case kCVPixelFormatType_DepthFloat32:
      self = .depth32Bit
    case kCVPixelFormatType_DisparityFloat16:
      self = .disparity16Bit
    case kCVPixelFormatType_DisparityFloat32:
      self = .disparity32Bit
    default:
      self = .unknown
    }
  }

  var cvPixelFormat: OSType {
    get throws(MediaError) {
      switch self {
      case .unknown, .depthPointCloud32Bit:
        throw .unsupportedDepthPixelFormat(self)
      case .depth16Bit:
        return kCVPixelFormatType_DepthFloat16
      case .depth32Bit:
        return kCVPixelFormatType_DepthFloat32
      case .disparity16Bit:
        return kCVPixelFormatType_DisparityFloat16
      case .disparity32Bit:
        return kCVPixelFormatType_DisparityFloat32
      }
    }
  }
}
