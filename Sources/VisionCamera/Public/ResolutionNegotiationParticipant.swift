// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a Camera Output that participates in resolution negotiations.
///
/// The desired target resolution is accessed when negotiating resolutions across all outputs conforming to this protocol.
///
/// This is required for using a ``Constraint/resolution(_:)`` for the given Camera Output, so the Camera pipeline can internally find a suitable resolution for all outputs.
public protocol ResolutionNegotiationParticipant {
  /// Get the target Resolution of this participant.
  ///
  /// This is used for finding a suitable Format and negotiated between other participants, possibly influenced by ``Constraint/resolution(_:)`` values.
  var targetResolution: ResolutionRule { get }

  /// Represents the stream type the target resolution specifies.
  var streamType: StreamType { get }
}
