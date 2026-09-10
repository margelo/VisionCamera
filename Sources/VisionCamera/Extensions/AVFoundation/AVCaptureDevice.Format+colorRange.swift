//
//  AVCaptureDevice.Format+colorRange.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 08.04.26.
//

import AVFoundation
import CoreMedia

extension AVCaptureDevice.Format {
  var colorRange: ColorRange {
    return formatDescription.mediaSubType.colorRange
  }
}
