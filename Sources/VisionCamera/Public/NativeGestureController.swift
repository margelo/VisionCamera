//
//  NativeGestureController.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 04.02.26.
//

import Foundation
import UIKit

/// The main-actor native extension point for attaching UIKit gesture recognizers to ``PreviewView``.
@MainActor
public protocol NativeGestureController: AnyObject {
  /// The concrete UIKit gesture recognizer type attached to a Preview View.
  associatedtype GestureRecognizer: UIGestureRecognizer

  /// Gets the underlying `UIGestureRecognizer`.
  var gestureRecognizer: GestureRecognizer { get }

  /// Called after this gesture recognizer is attached to a Preview View. The default implementation does nothing.
  func onAttached(to preview: PreviewView)
  /// Called after this gesture recognizer is removed from a Preview View. The default implementation does nothing.
  func onDetached(from preview: PreviewView)
}

extension NativeGestureController {
  /// Called after this gesture recognizer is attached to a Preview View. The default implementation does nothing.
  public func onAttached(to preview: PreviewView) {}
  /// Called after this gesture recognizer is removed from a Preview View. The default implementation does nothing.
  public func onDetached(from preview: PreviewView) {}
}
