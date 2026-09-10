//
//  MediaSampleMetadata.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 29.10.25.
//

import AVFoundation
import Foundation

/// Receives recorder lifecycle events for starting and stopping required native inputs. Events are delivered on the recorder's serial queue.
public protocol RecorderDelegate: AnyObject {
  /// Called right before starting the Recorder. This is a good time to ensure required inputs, such as an audio session, are running.
  func onRecorderWillStart()
  /// Called right after the Recorder stops and finishes writing. This is a good time to stop inputs, such as an audio session, if they are no longer used elsewhere.
  func onRecorderDidStop()
}
