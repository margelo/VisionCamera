// Copyright © 2025 Marc Rousavy @ Margelo

public enum ScannedObjectType: CaseIterable, Sendable {
  case unknown
  case codabar
  case code39
  case code39Mod43
  case code93
  case code128
  case ean8
  case ean13
  case gs1DataBar
  case gs1DataBarExpanded
  case gs1DataBarLimited
  case interleaved2Of5
  case itf14
  case upcE
  case aztec
  case dataMatrix
  case microPdf417
  case microQr
  case pdf417
  case qr
  case humanBody
  case humanFullBody
  case dogHead
  case dogBody
  case catHead
  case catBody
  case face
  case salientObject
}
