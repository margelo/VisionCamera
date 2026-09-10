//
//  AV+PreviewResizeMode.swift
//  Pods
//
//  Created by Marc Rousavy on 23.01.26.
//

import AVFoundation

extension PreviewResizeMode {
  func toAVLayerVideoGravity() -> AVLayerVideoGravity {
    switch self {
    case .aspectFill:
      return .resizeAspectFill
    case .aspectFit:
      return .resizeAspect
    }
  }
}
