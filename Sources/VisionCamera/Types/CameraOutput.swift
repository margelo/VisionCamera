// Copyright © 2025 Marc Rousavy @ Margelo

public protocol CameraOutput: AnyObject {
  var mediaType: MediaType { get }
  var outputOrientation: CameraOrientation { get set }
  var currentResolution: Size? { get }
}
