//
//  NativeGestureController.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 04.02.26.
//

import Foundation
import UIKit

@MainActor
public protocol NativeGestureController: AnyObject {
  associatedtype GestureRecognizer: UIGestureRecognizer

  /// Gets the underlying `UIGestureRecognizer`.
  var gestureRecognizer: GestureRecognizer { get }

  func onAttached(to preview: PreviewView)
  func onDetached(from preview: PreviewView)
}

extension NativeGestureController {
  public func onAttached(to preview: PreviewView) {}
  public func onDetached(from preview: PreviewView) {}
}
