///
/// AV+ColorSpace.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension ColorSpace {
  init(colorSpace: AVCaptureColorSpace) {
    switch colorSpace {
    case .sRGB:
      self = .srgb
    case .P3_D65:
      self = .p3D65
    case .HLG_BT2020:
      self = .hlgBt2020
    case .appleLog:
      self = .appleLog
    case .appleLog2:
      self = .appleLog2
    @unknown default:
      self = .unknown
    }
  }

  func toAVCaptureColorSpace() -> AVCaptureColorSpace? {
    switch self {
    case .unknown:
      return nil
    case .srgb:
      return .sRGB
    case .p3D65:
      return .P3_D65
    case .hlgBt2020:
      return .HLG_BT2020
    case .appleLog:
      guard #available(iOS 17.0, *) else { return nil }
      return .appleLog
    case .appleLog2:
      guard #available(iOS 26.0, *) else { return nil }
      return .appleLog2
    }
  }
}
