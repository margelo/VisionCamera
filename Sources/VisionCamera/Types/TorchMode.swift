// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the setting for the device's torch.
/// - ``TorchMode/on``: Keep the flash unit always on.
/// - ``TorchMode/off``: Keep the flash unit off. It can still fire elsewhere (e.g. for photo capture).
public enum TorchMode: CaseIterable, Sendable {
  /// Keep the flash unit always on.
  case on
  /// Keep the flash unit off. It can still fire elsewhere (e.g. for photo capture).
  case off

}
