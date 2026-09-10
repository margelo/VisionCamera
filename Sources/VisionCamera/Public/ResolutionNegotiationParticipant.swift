//
//  ResolutionNegotiationParticipant.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 08.04.26.
//

/// The media stream whose resolution participates in Camera format negotiation.
public enum StreamType {
  /// A video Frame stream.
  case video
  /// A still Photo stream.
  case photo
  /// A depth Frame stream.
  case depthVideo
  /// Depth data delivered with a Photo.
  case depthPhoto
}

// TODO: Do we want a flag that specifies aspect ratio and width/height rule? Maybe some things want to ignore order of width/height?
/// The target resolution rule evaluated while negotiating a Camera format.
public indirect enum ResolutionRule {
  /// Prefer the supported resolution closest to the supplied size, prioritizing aspect ratio before pixel count.
  case closestTo(Size)
  /// Prefer resolutions at least as large as the supplied size, ignoring aspect ratio and dimension order.
  case min(Size)
  /// Accept any supported resolution without a size preference.
  case any
}

/// Represents a Camera Output that participates in resolution negotiations.
///
/// The desired target resolution is accessed when negotiating resolutions across all outputs conforming to this protocol.
///
/// This is required for using a ``ResolutionBiasConstraint`` for the given Camera Output, so the Camera pipeline can internally find a suitable resolution for all outputs.
public protocol ResolutionNegotiationParticipant {
  /// Get the target Resolution of this participant.
  ///
  /// This is used for finding a suitable Format and negotiated between other participants, possibly influenced by ``ResolutionBiasConstraint``s.
  var targetResolution: ResolutionRule { get }

  /// Represents the stream type the target resolution specifies.
  var streamType: StreamType { get }
}
