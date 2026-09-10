// Copyright © 2025 Marc Rousavy @ Margelo

public struct FocusOptions: Equatable, Sendable {
  public var responsiveness: FocusResponsiveness?
  public var adaptiveness: SceneAdaptiveness?
  public var modes: [MeteringMode]?
  public var autoResetAfter: FocusReset?

  public init(
    responsiveness: FocusResponsiveness? = nil,
    adaptiveness: SceneAdaptiveness? = nil,
    modes: [MeteringMode]? = nil,
    autoResetAfter: FocusReset? = nil
  ) {
    self.responsiveness = responsiveness
    self.adaptiveness = adaptiveness
    self.modes = modes
    self.autoResetAfter = autoResetAfter
  }
}
