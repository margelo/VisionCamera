// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation
import Vision

@available(iOS 16.0, *)
final class BarcodeScanState {
  // scan() runs on the caller's queue, while cancel() can arrive from another queue.
  // This lock protects only the active operation's identity and cancellation flag.
  private let lock = NSLock()
  private var request: VNDetectBarcodesRequest?
  private var cancelled = false

  func begin(_ request: VNDetectBarcodesRequest) throws {
    lock.lock()
    defer { lock.unlock() }
    guard self.request == nil else { throw BarcodeScannerError.busy }
    self.request = request
    cancelled = false
  }

  func finish() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    request = nil
    return cancelled
  }

  func cancel() {
    lock.lock()
    let request = self.request
    if request != nil { cancelled = true }
    lock.unlock()
    // A completed operation's request is never reused by a subsequent scan.
    request?.cancel()
  }
}
