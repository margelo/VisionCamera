///
/// AutoFocusSystem+TargetVideoPixelFormat.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension TargetVideoPixelFormat {
  func toCVPixelFormatType() -> TargetCVPixelFormat {
    switch self {
    case .native:
      return .native
    case .yuv:
      return .specific(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
    case .rgb:
      return .specific(kCVPixelFormatType_32BGRA)
    }
  }
}
