# Scan barcodes in Frames and images

Install the optional scanner, then process images on your existing background queue.

## Install the module

For Swift Package Manager, add the `VisionCameraBarcodeScanner` product from the VisionCamera package to your app target. A package dependency looks like this:

```swift
.product(name: "VisionCameraBarcodeScanner", package: "VisionCamera")
```

SPM keeps the package's core deployment target at iOS 15.1. Scanner declarations require iOS 16. Guard scanner use with `if #available(iOS 16.0, *)` in an app that also supports iOS 15.

For CocoaPods, select the separate pod:

```ruby
platform :ios, '16.0'
pod 'VisionCameraBarcodeScanner', :git => 'https://github.com/margelo/VisionCamera.git', :branch => 'main'
```

Both package managers compile the same Swift source and use `import VisionCameraBarcodeScanner`. No ML Kit binary or model download is needed. The optional product depends on VisionCamera core and Apple system frameworks.

## Scan Camera Frames

Create one scanner and keep it for the lifetime of your frame-processing callback:

```swift
import VisionCamera
import VisionCameraBarcodeScanner

@available(iOS 16.0, *)
func startScanning() async throws -> (FrameOutput, BarcodeScanner) {
  let scanner = try BarcodeScanner(options: .init(symbologies: [.qr, .ean13]))
  let output = FrameOutput(options: .init(
    pixelFormat: .pixelFormat(.yuv4208BitFull),
    discardsLateFrames: true
  ))
  await output.setFrameHandler { frame in
    do {
      let barcodes = try scanner.scan(frame: frame)
      for barcode in barcodes {
        print(barcode.rawValue ?? "No text payload", barcode.boundingBox)
      }
    } catch BarcodeScannerError.cancelled {
      // The owner stopped scanning.
    } catch {
      print("Barcode scan failed: \(error)")
    }
  }
  return (output, scanner)
}
```

Attach the returned `FrameOutput` to your Camera session. Capture requires the core Camera permission and `NSCameraUsageDescription`. Scanning an existing image requires neither Camera access nor a usage description.

The callback executes on the output's serial queue. Scanning stays on that queue, and AVFoundation drops late Frames while the callback is busy. Do not dispatch every Frame into an unbounded queue. Move UI updates to the main actor after copying the values your view needs.

To stop processing, cancel the current request and remove the callback:

```swift
scanner.cancel()
await output.setFrameHandler(nil)
```

Cancellation is cooperative. Vision may finish its current work before returning. The scanner discards a cancelled operation's results and throws `BarcodeScannerError.cancelled`. Removing the callback returns after any active callback finishes. Cancellation affects only the operation that was active when `cancel()` acquired its state lock; subsequent scans remain usable.

## Scan an image

Call the scanner on a background queue that your app owns:

```swift
let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
let barcodes = try scanner.scan(image: image) // UIImage or CGImage
```

For a `CVPixelBuffer`, pass its EXIF orientation explicitly:

```swift
let barcodes = try scanner.scan(pixelBuffer: pixelBuffer, orientation: .right)
```

Do not mutate or invalidate the native input during a scan. The scanner retains the input for the synchronous call and returns value snapshots. Results remain valid after you release a Frame, release an image, or reuse the scanner. The scanner does not retain a Frame's camera buffer between calls.

## Use the result coordinates

`Barcode.boundingBox` and `Barcode.cornerPoints` use pixels in the image after applying orientation and mirroring. Their origin is at the top left. A 1920-by-1080 buffer scanned with `.right` has an `imageSize` of 1080 by 1920. `UIImage.scale` does not change these dimensions.

The scanner converts Vision's normalized coordinates with a lower-left origin to this pixel coordinate system. It scans the entire image and does not set a region of interest. It preserves observations outside the image bounds. The corner order is Vision's top-left, top-right, bottom-right, bottom-left order around the detected symbol.

To draw on a preview, apply the preview's crop, scaling, and layout transform separately. Results are not in preview-view coordinates. Do not multiply or rotate them again using the original Frame dimensions.

## Keep processing within the frame budget

Select only the formats your app needs. Use `FrameOutputOptions.targetResolution` and a `ResolutionBiasConstraint` to negotiate an appropriate resolution. Preview-sized buffers are available on iOS 17 and later. On iOS 16, choose a suitable negotiated resolution.

Measure scan duration on the device. The scanner has no internal image queue, permits one outstanding scan, and rejects concurrent calls with `BarcodeScannerError.busy`. Separate scanner instances process independently. Limit the number of instances and retain each input only until its scan returns.
