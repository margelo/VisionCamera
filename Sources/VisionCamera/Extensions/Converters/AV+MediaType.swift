///
/// MediaType+toAVMediaType.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension MediaType {
  init(type: AVMediaType) {
    switch type {
    case .video:
      self = .video
    case .depthData:
      self = .depth
    case .metadataObject:
      self = .metadata
    default:
      self = .other(type)
    }
  }

  func toAVMediaType() -> AVMediaType {
    switch self {
    case .video:
      return .video
    case .depth:
      return .depthData
    case .metadata:
      return .metadataObject
    case .other(let type):
      return type
    }
  }
}
