import CoreImage
import Foundation
import Vision
import XCTest

@available(iOS 16.0, *)
enum BarcodeRuntimeSupport {
  static func requireDetection(revision: Int? = nil) throws {
    #if targetEnvironment(simulator)
      let supported: Bool
      if revision == 3 {
        supported = try revision3.get()
      } else if #available(iOS 17.0, *) {
        supported = try revision4.get()
      } else {
        supported = try revision3.get()
      }
      guard supported else {
        throw XCTSkip(
          "Native Vision's ML detector cannot decode a known-valid QR fixture on this simulator (\(ProcessInfo.processInfo.operatingSystemVersionString)). "
            + "Detection assertions run against the maintained scanner in the macOS host suite; verify iPhone accuracy and performance on hardware.")
      }
    #endif
  }

  #if targetEnvironment(simulator)
    private static let revision3 = Result { try nativeDetectorCanDecode(revision: 3) }
    private static let revision4 = Result { try nativeDetectorCanDecode(revision: 4) }

    private static func nativeDetectorCanDecode(revision: Int) throws -> Bool {
      // This probe deliberately does not call BarcodeScanner, its configuration helpers, or its fixture helper.
      // An implementation regression must still fail when the independent native detector works.
      let payload = "VisionCamera native Vision capability probe"
      let generator = try XCTUnwrap(CIFilter(name: "CIQRCodeGenerator"))
      generator.setValue(Data(payload.utf8), forKey: "inputMessage")
      generator.setValue("M", forKey: "inputCorrectionLevel")
      let code = try XCTUnwrap(generator.outputImage).transformed(by: CGAffineTransform(scaleX: 10, y: 10))
      let background = CIImage(color: .white).cropped(to: code.extent.insetBy(dx: -60, dy: -60))
      let image = try XCTUnwrap(CIContext().createCGImage(code.composited(over: background), from: background.extent))
      let request = VNDetectBarcodesRequest()
      request.revision = revision
      request.symbologies = [.qr]
      if #available(iOS 17.0, *) {
        for (stage, devices) in try request.supportedComputeStageDevices {
          if let cpu = devices.first(where: {
            if case .cpu = $0 { return true }
            return false
          }) {
            request.setComputeDevice(cpu, for: stage)
          }
        }
      } else {
        request.usesCPUOnly = true
      }
      do {
        try VNImageRequestHandler(cgImage: image).perform([request])
      } catch {
        let nativeError = error as NSError
        if nativeError.domain == VNErrorDomain,
          nativeError.code == VNErrorCode.internalError.rawValue,
          nativeError.localizedDescription == "Could not create inference context"
        {
          return false
        }
        throw error
      }
      return request.results?.contains { $0.payloadStringValue == payload } == true
    }
  #endif
}
