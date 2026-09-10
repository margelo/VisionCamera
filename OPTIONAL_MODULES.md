# Optional native modules

Each optional feature has its own SPM library product and CocoaPod with the same Swift module name. All package managers compile the maintained source in `Sources/`. There are no external SDK downloads or runtime bridges.

| Product and import | Minimum iOS | Dependencies |
| --- | --- | --- |
| `VisionCamera` | 15.1 | Apple frameworks |
| `VisionCameraResizer` | 15.1 | `VisionCamera`, Metal |
| `VisionCameraBarcodeScanner` | 16 | `VisionCamera`, Vision |
| `VisionCameraLocation` | 15.1 | Core Location, Foundation |

The SPM package keeps its iOS 15.1 platform declaration. Scanner declarations carry iOS 16 availability because Vision's ML barcode detector starts with request revision 3 in iOS 16. CocoaPods gives the scanner pod an iOS 16 deployment target. An app targeting iOS 15.1 can link the SPM scanner product and guard its use with `if #available(iOS 16.0, *)`.

## Install selected products

SPM is the recommended distribution. In Xcode's package product picker, add only the features your app uses. In a package target, select products explicitly:

```swift
.target(
  name: "YourApp",
  dependencies: [
    .product(name: "VisionCamera", package: "VisionCamera"),
    .product(name: "VisionCameraResizer", package: "VisionCamera"),
    .product(name: "VisionCameraBarcodeScanner", package: "VisionCamera"),
    .product(name: "VisionCameraLocation", package: "VisionCamera"),
  ]
)
```

For CocoaPods, use separate pods from the same repository revision:

```ruby
platform :ios, '16.0'
use_frameworks! :linkage => :static

camera_source = {
  :git => 'git@github.com:margelo/VisionCamera.git',
  :branch => 'main'
}
pod 'VisionCamera', camera_source
pod 'VisionCameraResizer', camera_source
pod 'VisionCameraBarcodeScanner', camera_source
pod 'VisionCameraLocation', camera_source
```

Remove pods you do not need. A location-only app needs only `VisionCameraLocation`. Resizer and scanner users must also point the core pod at this repository until a matching core release is published. The existing `0.1.0` tag predates these modules; it cannot install them. Pin all selected pods to the same commit or future release for reproducible builds.

Subspecs select sources within a pod and inherit root attributes; they do not establish independent Swift module identities. Separate podspecs give each feature its own target and `module_name`, matching SPM. The consumer validation builds each selection and compiles explicit imports under both package managers. [CocoaPods specification reference](https://guides.cocoapods.org/syntax/podspec.html), [Swift package products and targets](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html).

## Process native frames

Register a closure with `await frameOutput.setOnFrameCallback(onFrame:)`. The output delivers frames on its serial queue. Resizing and scanning finish synchronously on that queue, so default late-frame dropping bounds capture work. Dispose each frame after processing. Removing the callback waits until current synchronous processing returns. The scanner also exposes cancellation; Metal commands already submitted by the resizer finish before it returns.

Reuse the processor instances across frames. The resizer owns reusable Metal resources and a bounded pool of result buffers. Retain a result until every consumer, including your own asynchronous GPU command, finishes reading it. Neither module creates a worklet runtime or drawing layer.

The installed iOS 18.5 and 26.5 simulators did not decode valid barcodes with native Vision's ML revisions, even when using the CPU. Detection tests report this limitation through an independent native probe. A macOS test harness compiles the same maintained scanner backend and runs real fixture detection. The harness does not add macOS support to the distributed package. Physical iPhone camera accuracy, permission prompts, GPU timing, GPS accuracy, and App Review acceptance still require device or external checks.

Read the module guides for exact formats, coordinates, ownership, and permission behavior:

- [GPU resizer](Sources/VisionCameraResizer/Documentation.docc/VisionCameraResizer.md)
- [Vision barcode scanner](Sources/VisionCameraBarcodeScanner/Documentation.docc/VisionCameraBarcodeScanner.md)
- [Foreground location](Sources/VisionCameraLocation/Documentation.docc/VisionCameraLocation.md)
- [Runnable optional feature example and public-consumer matrix](OptionalExample/README.md)

## Source provenance

The optional modules adapt committed iOS code and API behavior from `margelo/react-native-vision-camera`, revision `91bae1f08d549b50444ee16661dc4f4375cba0b6`:

- `packages/react-native-vision-camera-resizer`, including its Metal kernels and tensor options.
- `packages/react-native-vision-camera-barcode-scanner`, including scanning inputs, format selection, and callback behavior. Vision replaces the Google ML Kit backend; rich result differences are documented in the scanner guide.
- `packages/react-native-vision-camera-location`, including accuracy, distance filtering, and native location updates.

The source checkout's uncommitted changes were not used or modified. The repository's [MIT license](LICENSE) preserves Marc Rousavy's 2025 copyright; adapted files retain applicable source notices. Google's SDK and models are not redistributed. See the scanner guide for the backend decision and official distribution and licensing sources.
