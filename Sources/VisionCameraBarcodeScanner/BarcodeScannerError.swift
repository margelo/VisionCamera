// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation
import Vision

/// A scanner configuration, concurrency, cancellation, or input error.
@available(iOS 16.0, *)
public enum BarcodeScannerError: Error, LocalizedError {
  /// A scan is already running on this scanner. The new input was not queued.
  case busy
  /// The accepted scan was cancelled before its results were returned.
  case cancelled
  /// The requested symbology list was empty. Use `nil` to scan all supported formats.
  case emptySymbologies
  /// The running OS and request revision do not support these requested symbologies.
  case unsupportedSymbologies([VNBarcodeSymbology])
  /// The image has no supported backing image, finite extent, or known orientation.
  case unsupportedImage

  /// A description suitable for logs and error presentation.
  public var errorDescription: String? {
    switch self {
    case .busy: return "This BarcodeScanner is already processing an image."
    case .cancelled: return "The barcode scan was cancelled."
    case .emptySymbologies: return "Select at least one symbology, or use nil to scan all supported formats."
    case .unsupportedSymbologies(let formats):
      return "Vision does not support these barcode symbologies: \(formats.map(\.rawValue).joined(separator: ", "))."
    case .unsupportedImage: return "The image has no supported backing image, finite extent, or known orientation."
    }
  }
}
