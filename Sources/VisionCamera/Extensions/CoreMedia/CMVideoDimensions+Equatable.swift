//
//  CMVideoDimensions+Equatable.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 08.04.26.
//

import CoreMedia

// Preserve the existing resolution deduplication behavior.
// swift-format-ignore: AvoidRetroactiveConformances
/// Equality for video dimensions based on their width and height.
extension CMVideoDimensions: @retroactive Equatable {
  /// Returns whether two video dimensions have the same width and height.
  ///
  /// - Parameters:
  ///   - lhs: The first dimensions to compare.
  ///   - rhs: The second dimensions to compare.
  /// - Returns: `true` if both widths and both heights are equal.
  public static func == (lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
    lhs.width == rhs.width && lhs.height == rhs.height
  }
}
