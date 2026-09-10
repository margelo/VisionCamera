//
//  AVCaptureDevice.Format+bitDepth.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 08.04.26.
//

import AVFoundation
import CoreMedia

extension AVCaptureDevice.Format {
  var bitDepth: DynamicRangeBitDepth {
    return formatDescription.mediaSubType.bitDepth
  }
}
