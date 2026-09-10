// Copyright © 2026 Marc Rousavy @ Margelo

import Vision

/// Selects the barcode symbologies passed to Apple's Vision detector.
@available(iOS 16.0, *)
public struct BarcodeScannerOptions {
  /// The symbologies to detect, or `nil` to detect all formats supported by the selected Vision revision.
  ///
  /// Restrict this list to the formats your app uses to reduce processing time. An empty list or
  /// an unsupported symbology makes ``BarcodeScanner/init(options:)`` throw.
  /// Vision reports UPC-A codes as EAN-13 with a leading zero. See <doc:BarcodeBackend>.
  public var symbologies: [VNBarcodeSymbology]?

  /// Creates options that detect the supplied symbologies, or all supported symbologies by default.
  public init(symbologies: [VNBarcodeSymbology]? = nil) {
    self.symbologies = symbologies
  }
}
