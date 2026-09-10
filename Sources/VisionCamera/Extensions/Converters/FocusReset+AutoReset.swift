extension FocusReset {
  func toAutoReset() -> MeteringTask.AutoReset {
    switch self {
    case .never: return .never
    case .after(let seconds): return .after(seconds: seconds)
    }
  }
}
