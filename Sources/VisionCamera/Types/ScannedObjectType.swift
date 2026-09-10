// Copyright © 2025 Marc Rousavy @ Margelo

public enum ScannedObjectType: String, CaseIterable, Sendable {
  case unknown
  case codabar
  case code39 = "code-39"
  case code39Mod43 = "code-39-mod-43"
  case code93 = "code-93"
  case code128 = "code-128"
  case ean8 = "ean-8"
  case ean13 = "ean-13"
  case gs1DataBar = "gs1-data-bar"
  case gs1DataBarExpanded = "gs1-data-bar-expanded"
  case gs1DataBarLimited = "gs1-data-bar-limited"
  case interleaved2Of5 = "interleaved-2-of-5"
  case itf14 = "itf-14"
  case upcE = "upc-e"
  case aztec
  case dataMatrix = "data-matrix"
  case microPdf417 = "micro-pdf-417"
  case microQr = "micro-qr"
  case pdf417 = "pdf-417"
  case qr
  case humanBody = "human-body"
  case humanFullBody = "human-full-body"
  case dogHead = "dog-head"
  case dogBody = "dog-body"
  case catHead = "cat-head"
  case catBody = "cat-body"
  case face
  case salientObject = "salient-object"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
