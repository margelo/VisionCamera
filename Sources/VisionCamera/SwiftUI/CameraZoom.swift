// Copyright © 2026 Marc Rousavy @ Margelo

import SwiftUI

@MainActor
enum CameraZoom {
  case value(Double)
  case binding(Binding<Double>)

  var value: Double {
    switch self {
    case .value(let value): return value
    case .binding(let binding): return binding.wrappedValue
    }
  }

  var isFixed: Bool {
    if case .value = self { return true }
    return false
  }
}
