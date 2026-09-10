// Copyright © 2026 Marc Rousavy @ Margelo

#if USE_VISIONCAMERA
  import Foundation
  import VisionCamera
  #if USE_VISIONCAMERARESIZER
    import VisionCameraResizer
  #endif
  #if USE_VISIONCAMERABARCODESCANNER
    import VisionCameraBarcodeScanner
  #endif

  // Constructed before registration, then accessed only on FrameOutput's serial queue.
  final class ExampleFrameProcessor {
    private var nextProcessingTime = Date.distantPast
    #if USE_VISIONCAMERARESIZER
      private let resizer: GPUResizer
    #endif
    #if USE_VISIONCAMERABARCODESCANNER
      private let scanner: BarcodeScanner
    #endif

    init() throws {
      #if USE_VISIONCAMERARESIZER
        resizer = try GPUResizer(options: .init(width: 224, height: 224))
      #endif
      #if USE_VISIONCAMERABARCODESCANNER
        scanner = try BarcodeScanner()
      #endif
    }

    func process(_ frame: Frame) -> String? {
      let now = Date()
      guard now >= nextProcessingTime else { return nil }
      nextProcessingTime = now.addingTimeInterval(1)
      do {
        var message = "Frame: \(frame.width) x \(frame.height)"
        #if USE_VISIONCAMERARESIZER
          let result = try resizer.resize(frame)
          message += "\nGPU tensor: \(result.width) x \(result.height)"
        #endif
        #if USE_VISIONCAMERABARCODESCANNER
          let barcodes = try scanner.scan(frame: frame)
          message += "\nBarcodes: \(barcodes.count)"
          if let payload = barcodes.first?.rawValue { message += "\n\(payload)" }
        #endif
        return message
      } catch {
        return error.localizedDescription
      }
    }
  }
#endif
