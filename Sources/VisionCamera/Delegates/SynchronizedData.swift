// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

enum SynchronizedData {
  case video(CMSampleBuffer)
  case depth(AVDepthData)
}
