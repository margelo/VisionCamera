# The native barcode backend

The optional scanner uses Apple Vision to provide the same maintained Swift implementation through Swift Package Manager and CocoaPods.

## Why Vision

The original React Native implementation uses `GoogleMLKit/BarcodeScanning` 9.0.0. Google's [official iOS migration guide](https://developers.google.com/ml-kit/migration/ios) states that ML Kit is distributed only through CocoaPods and requires iOS 15.5 or later. Google's [release notes](https://developers.google.com/ml-kit/release-notes) list GoogleMLKit 9.0.0 and its MLKitBarcodeScanning 8.0.0 component, and its [official sample Podfile](https://github.com/googlesamples/mlkit/blob/master/ios/quickstarts/vision/Podfile) uses GoogleMLKit 9.0.0. There is no official SPM distribution documented in those installation instructions, checked September 10, 2026.

ML Kit's [terms](https://developers.google.com/ml-kit/terms) incorporate the Google APIs Terms of Service and impose restrictions on extracting or reverse engineering its models and software. The SDK's terms are separate from this project's MIT license and from Google's documentation sample license. This module does not redistribute or repackage Google binaries. An unofficial binary package would need its own provenance, license review, and maintenance decision.

Apple describes [barcode request revision 3](https://developer.apple.com/videos/play/wwdc2022/10024/) as using machine learning, unlike earlier revisions. That revision requires iOS 16. The scanner therefore requires iOS 16 and never falls back to an older non-ML request on iOS 15. It explicitly selects revision 3 on iOS 16 and revision 4 on iOS 17 and later. The latter improves detection and exposes raw payload data.

This is an image-based Vision detector. The core `ObjectOutput` continues to use AVFoundation metadata detection and has a separate result API. Importing this module does not create a Camera output or start a scanner automatically.

Vision is an Apple system framework linked from the platform SDK, so neither package manager downloads a third-party model or binary archive. Swift Package Manager's [target model](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html) gives each target its own module. The separate CocoaPod preserves the `VisionCameraBarcodeScanner` Swift import.

Simulator builds select CPU compute devices because the tested simulator's default accelerator selection fails to create an inference context. On iOS 17 and later, the scanner queries Vision's supported compute devices once during initialization and uses [`setComputeDevice(_:for:)`](https://developer.apple.com/documentation/vision/vnrequest/setcomputedevice(_:for:)) for each supported CPU stage. On the iOS 16 simulator, it uses `usesCPUOnly`. This changes the compute device, not the ML detector revision. Physical devices let Vision choose its accelerators. Simulator timings do not represent device performance.

## Format and payload differences

The native options use Apple's [`VNBarcodeSymbology`](https://developer.apple.com/documentation/vision/vnbarcodesymbology) directly. `BarcodeScanner.supportedSymbologies()` reports the formats for the selected revision on the running OS. Initialization rejects unsupported formats and an empty filter.

The original format names map as follows:

| Original format | Native Vision symbology |
| --- | --- |
| Code 128 | `.code128` |
| Code 39 | `.code39` |
| Code 93 | `.code93` |
| Codabar | `.codabar` |
| Data Matrix | `.dataMatrix` |
| EAN-13 | `.ean13` |
| EAN-8 | `.ean8` |
| ITF | `.i2of5` |
| QR Code | `.qr` |
| UPC-A | `.ean13`, including a leading zero in the decoded text |
| UPC-E | `.upce` |
| PDF417 | `.pdf417` |
| Aztec | `.aztec` |
| All formats | `nil` |

Vision may support further symbologies. Format variants with checksums, full ASCII, or GS1 behavior remain distinct native values; the module does not collapse them into the original format enum. Detection accuracy, duplicate handling, and damaged-code behavior can differ between backends.

`Barcode.rawValue` is Vision's [`payloadStringValue`](https://developer.apple.com/documentation/vision/vnbarcodeobservation/payloadstringvalue). It can be absent for binary or undecodable payloads. `Barcode.payloadData` returns Apple's [`payloadData`](https://developer.apple.com/documentation/vision/vnbarcodeobservation/payloaddata) unchanged on iOS 17 and later and is absent on iOS 16. Apple describes this as a raw representation. Its meaning depends on the symbology; it is not promised to be the original message bytes or ML Kit's `rawData`.

In the tested QR fixture, Vision's payload data equals `CIQRCodeDescriptor.errorCorrectedPayload` and contains encoding headers and padding. The 28-byte text message produces 44 bytes of native payload data. The API name preserves this native distinction. Do not decode this field as UTF-8 or treat it as a replacement for ML Kit's raw bytes. Use `rawValue` when your app needs decoded text.

ML Kit additionally provides display values and semantic classifications such as contact, Wi-Fi, URL, and driver-license content. The original package exposed `displayValue` and `valueType`, but its iOS wrapper did not expose ML Kit's typed parsed payload objects. Vision does not promise the same classifications or formatting. The native module omits those properties. Parse the decoded text in your app when you need a specific content type; do not assume that every decoded string is a URL.

Vision's [`boundingBox`](https://developer.apple.com/documentation/vision/vndetectedobjectobservation/boundingbox) and corners are converted to oriented image pixels with a top-left origin. The macOS host tests compile the maintained scanner implementation and cover generated QR, PDF417, Aztec, Code 128, and UPC-A fixtures, all eight EXIF orientations, native payload-data preservation, filtering, retained result values, and cancellation admission. The host-only validation package excludes the iOS Frame and UIImage adapters; it is not a published macOS product.

On the tested iOS 18.5 and iOS 26.5 simulators, an independent native Vision request fails to decode a known-valid QR image, including with supported CPU compute devices. Detection-dependent simulator tests skip only when that independent reference probe fails. A scanner regression still fails when the native probe succeeds. Format validation, native-observation coordinate conversion, image-orientation mapping, invalid-input handling, and cancellation admission remain tested on the simulator. Run `bash scripts/test-barcode-host.sh` for the maintained backend's detection tests. Real iPhone scanning, iOS 16 runtime behavior, and Camera integration accuracy still require hardware validation. These fixtures do not establish equivalent accuracy to ML Kit across real camera scenes or every supported symbology.

## Source provenance

This module adapts the scanner, result, options, format selection, orientation handling, and callback use cases from `packages/react-native-vision-camera-barcode-scanner` at source revision [`91bae1f08d549b50444ee16661dc4f4375cba0b6`](https://github.com/margelo/react-native-vision-camera/tree/91bae1f08d549b50444ee16661dc4f4375cba0b6/packages/react-native-vision-camera-barcode-scanner). That committed source was read without modifying its checkout. Marc Rousavy's authorship and applicable copyright notices are retained under this repository's MIT license.
