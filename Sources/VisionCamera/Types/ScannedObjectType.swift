// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the type of a ``ScannedObject``.
public enum ScannedObjectType: CaseIterable, Sendable {
  /// An unknown metadata object.
  case unknown
  /// A Codabar code.
  case codabar
  /// A Code 39 code.
  case code39
  /// A Code 39 with Modulo 43 checksums code.
  case code39Mod43
  /// A Code 93 code.
  case code93
  /// A Code 128 code.
  case code128
  /// A EAN-8 code.
  case ean8
  /// A EAN-13 code.
  case ean13
  /// A GS1 DataBar code.
  case gs1DataBar
  /// A GS1 DataBar Expanded code.
  case gs1DataBarExpanded
  /// A GS1 DataBar Limited code.
  case gs1DataBarLimited
  /// A Interleaved 2 of 5 code.
  case interleaved2Of5
  /// A ITF-14 code.
  case itf14
  /// A UPC-E code.
  case upcE
  /// A Aztec code.
  case aztec
  /// A Data Matrix code.
  case dataMatrix
  /// A MicroPDF417 code.
  case microPdf417
  /// A Micro QR code.
  case microQr
  /// A PDF417 code.
  case pdf417
  /// A QR code.
  case qr
  /// A detected human body.
  case humanBody
  /// A detected full human body.
  case humanFullBody
  /// A detected dog head.
  case dogHead
  /// A detected dog body.
  case dogBody
  /// A detected cat head.
  case catHead
  /// A detected cat body.
  case catBody
  /// A detected face.
  case face
  /// A visually salient object.
  case salientObject

}
