# Apple camera API audit

This audit follows the public API through its native implementation, converters, constraints, callbacks, and repository consumers. The comparison source is react-native-vision-camera commit `91bae1f08d549b50444ee16661dc4f4375cba0b6`. The starting VisionCamera commit is `2ed3faab7a327885a49f39037797262051c2968f`.

The deployment target remains iOS 15.1, with Swift 5 language mode. Apple SDK availability checks govern newer features. UIKit, Swift Package Manager, and CocoaPods remain supported.

## Reviewed APIs

| Area | Inventory and native behavior checked |
| --- | --- |
| Discovery and capabilities | `VisionCamera`, `CameraDevice`, device types and positions, default/user-preferred camera selection, virtual constituents, external and Continuity cameras, discovery listeners, supported resolutions, FPS, dynamic ranges, stabilization, metering, lens and white-balance capabilities |
| Session and negotiation | Both native session classes, connections, output configuration, every `Constraint` case and resolver, strict rejection, fallback ordering, resolved values, resolution rules, audio setup, interruption/error/running callbacks, orientation managers |
| Controls and preview | `CameraController`, configuration, focus options/reset/responsiveness/adaptiveness, metering points, exposure, white balance, torch, zoom, low-light boost, distortion correction, preview outputs/views, gestures, coordinate conversions |
| Photos | Output options, target and observed containers, capture settings, prepared settings, all photo callbacks, quality prioritization, flash, RAW/ProRAW, depth, calibration, preview images, `Photo`, `PhotoFile`, metadata, file export |
| Video and audio | Both recording backends, output options/settings, codec discovery and selection, recorder settings and lifecycle callbacks, pause/resume, duration/file-size limits, audio input, timestamps, timelines, native location metadata |
| Frames and depth | Output options, exact pixel formats, dynamic-range conversions, buffer delivery/rotation, deferred start, filtering, frame planes, disposal/ARC lifetime, depth conversion, calibration, native buffers, byte access, rendering and image conversion |
| Metadata and synchronization | Requested object types, native object/code/face models, unknown native identifiers, face angles and IDs, synchronized output validation, sample types, dropped samples, timestamps, per-output presentation metadata |
| Native extension points | `NativeCameraOutput`, `NativePreviewViewOutput`, `NativeGestureController`, `ResolutionNegotiationParticipant`, `RecorderDelegate`, `MediaSampleMetadata`, native capture objects and retained buffers |
| Value models and consumers | Geometry and ranges, errors and subscriptions, output/stream/media categories, all current examples and tests, README, maintained DocC guides and public declaration comments |

## Removals and migration

| Previous API or behavior | Apple API and rationale |
| --- | --- |
| `PixelFormat.private`, `PixelFormat.depthPointCloud32Bit`, `DepthPixelFormat.depthPointCloud32Bit` | Removed Android `PRIVATE` and `DEPTH_POINT_CLOUD` concepts. AVDepthData uses depth/disparity pixel maps. Native pixel-format identifiers remain extensible. |
| `DeviceType.quad`, `DeviceType.timeOfFlightDepth` | Removed device categories without an AVFoundation camera type. Apple's TrueDepth and LiDAR device types remain. |
| Closed `PixelFormat` enum and coarse `.yuv`/`.rgb` frame targets | `PixelFormat(rawValue:)` preserves the exact Core Video identifier, including compressed and future formats. Request `.pixelFormat(.rgbBgra8Bit)` or another exact format. Unsupported output formats throw during configuration. |
| `PhotoHDRConstraint` and `supportsPhotoHDR` | Removed a constraint that the resolver ignored and a capability fixed to `false`. Apple photo processing remains available; there is no equivalent HDR toggle in this API. |
| `ColorSpace.dolbyVision`, `TargetColorSpace.dolbyVision` | Removed a capture color-space request with no `AVCaptureColorSpace` representation. Request `.hlgBt2020` for Apple's HLG capture workflow. Dolby Vision recording is not classified as unsupported. |
| `.sdr8Bit` / `.hdr10Bit` | Use `.bit8` / `.bit10`. Bit depth alone does not specify HDR. Resolved constraints report `DynamicRange`, preserving unknown bit-depth/range observations instead of coercing them to 8-bit video range. |
| `isPhotoHDREnabled` | Use `supportsHighestPhotoQuality` for the actual `AVCaptureDevice.Format.isHighestPhotoQualitySupported` observation. This is a quality capability, not an HDR state. |
| Metadata orientation and mirroring | `ObjectOutput.outputOrientation` is read-only and describes native unrotated coordinates. Explicit mirroring is rejected; use preview metadata conversion for overlays. |
| Ignored preview orientation setter | `PreviewOutput.outputOrientation` is read-only because the interface orientation manager controls the preview. `CameraOutput` requires only a getter; concrete capture outputs and `VideoOutput` retain writable orientation. |
| Metering radius/size | `MeteringPoint` contains normalized coordinates. `PreviewView.meteringPoint(at:)` has no size argument. The removed size never reached AVFoundation. Newer native rectangle-of-interest APIs remain accessible through the native device. |
| Focus, exposure, white-balance, torch, and permission wrappers | Use `AVCaptureDevice` mode types and `AVAuthorizationStatus`. Native one-shot modes, torch `.auto`, and future values no longer collapse into a different mode. |
| White-balance scalar structs | Use `AVCaptureDevice.WhiteBalanceGains` and `WhiteBalanceTemperatureAndTintValues`. Use `supportsCustomLensPosition`, `supportsCustomExposure`, and `supportsCustomWhiteBalanceGains` before specifying values. The existing locking capabilities now describe locking the current value, which Apple supports separately. |
| `OutputStreamType` and `getSupportedResolutions(outputStreamType:)` | Use `getSupportedResolutions(streamType:)` with the existing `StreamType` used by native format negotiation. Both recording and frame delivery use `.video`; `.photo`, `.depthPhoto`, and `.depthVideo` keep their native resolution queries. |
| Constant capability properties | Removed `supportsSpeedQualityPrioritization`, `supportsExposureBias`, `supportsPreviewImage`, `supportsTorchStrength`, and `isUsedByAnotherApp`. Native bounds, supported modes, output configuration, and session interruption callbacks describe actual behavior. |
| Arbitrary torch strength range | Use `torchLevel` and `setTorchModeOn(level:)`, including Apple's maximum-available-level sentinel. Invalid levels throw before native configuration. |
| Optional defaults with no distinct meaning | Focus options use concrete defaults. Video audio enablement is a `Bool`. Integer bit rates and byte limits replace bridge-driven `Double` values. Optional device/session configuration values remain where `nil` means leave the current setting unchanged. |
| `VideoCodec`, `VideoOutputSettings`, `setOutputSettings` | Use native `AVVideoCodecType` and `setVideoCodec(_:)`. Empty settings no longer cause a silent no-op, and new Apple codecs retain their identifiers. |
| Shared video output `fileType` | `MovieFileVideoOutput` writes QuickTime `.mov`. Select `.mov` or `.mp4` with `VideoFrameOutput(options:fileType:)`. |
| Photo `.native` and separate compression quality | Use `.automatic(quality:)`, `.jpeg(quality:)`, `.heic(quality:)`, or `.dng`. Automatic selects advertised HEVC, then JPEG. RAW has no ignored compression-quality parameter. |
| Per-photo depth request without output preparation | Set `PhotoOutputOptions.enableDepthDataDelivery` before capture. Unsupported explicit depth/preview/distortion/shutter requests throw instead of being silently ignored. |
| Single-photo calibration request flag | Removed a flag that requires native constituent-photo delivery of multiple cameras, which this single-photo method never configured. Native `AVCapturePhotoOutput`, captured calibration data, and depth calibration remain accessible. |
| `ScannedObjectType` | Use `AVMetadataObject.ObjectType`. Requested types must be supported by the connected output. Native future identifiers remain intact. |
| Face flags plus nonoptional angles | `ScannedFace.rollAngle` and `yawAngle` are optional. Missing native angles are not read, avoiding AVFoundation exceptions. `faceID` is an `Int`. |
| Calibration matrices as `[Double]` | Use native SIMD matrices with fixed dimensions. Index focal lengths with `[0, 0]` and `[1, 1]`. Frame attachments are length-checked and copied without assuming byte alignment. |
| Duplicate native-buffer bridge methods | Use `pixelBuffer` or `getPixelBuffer()`. The underlying Core Video object stays retained and available to native extensions. |
| Newer properties with silent old-OS fallback values | Availability annotations expose user-preferred cameras, Continuity queries, focal length, displayable zoom, and background-audio controls on the OS versions that implement them. The minimum deployment target is unchanged. |

## Behavior corrections

A multi-camera session negotiates multi-camera-compatible formats even with one connected input. This preserves valid single virtual-device combinations. Stabilization preferences apply only to connections from the camera being configured, so one camera cannot overwrite another camera's settings. Built-in outputs expose immutable native stream types. `isLowLightBoostEnabled` now reports active native boost instead of the preference to enable it automatically.

Format negotiation uses finite fallback chains. Automatic stabilization cannot fall back to itself forever. FPS requests preserve fractional rates and reject invalid values. Explicit capture color selection disables AVFoundation's automatic wide-color selection before setting the requested color space. Extended dynamic range is not toggled merely because a format has 10-bit components. AVFoundation manages its separate exposure-fusion HDR setting. Selected dynamic range describes the native format without rewriting unknown component properties. Device-level configuration checks now include frame rate, stabilization, and dynamic range; connected outputs still require session configuration.

`NativeCameraOutput.configure(config:)` and `NativePreviewViewOutput.configure(config:)` can throw. Existing nonthrowing conformers still satisfy the protocol. Implementations use this boundary to validate explicit settings before calling Objective-C setters that can raise exceptions. Explicit frame pixel formats, camera-matrix delivery, and initial physical transforms are checked on the connected output. Preview-sized frame buffers requested on an older OS throw. Deferred start remains a preference on outputs that support it.

Depth conversion verifies the requested type against the individual `AVDepthData.availableDepthDataTypes` before calling AVFoundation. Unrecognized depth types report `.unknown` and are omitted from the wrapper's advertised conversion targets; native depth data remains accessible.

Metadata synchronization retains metadata samples, including empty results, and native audio samples. Each video/depth sample uses its own output's presentation metadata. Synchronizer creation rejects unsupported and duplicate outputs. AVFoundation replaces each synchronized output's individual delegate, so callers use the synchronizer callback while it owns those outputs.

Both recorders validate duration and file-size limits before native numeric conversion. Frame-based recording compares the encoded file's size with its limit. Encoder buffering can cause the final file to exceed that limit. Native codec recommendations are selected for the requested codec and file type.

## Apple functionality retained

External, Continuity, virtual, TrueDepth, and LiDAR cameras remain valid. Device discovery uses SDK availability rather than the capabilities of a particular simulator.

Core Video includes RGB layouts, RAW Bayer formats, compressed YUV, and depth/disparity buffers. A format missing from one output's supported list does not make it invalid for native input, processing, or another output. Exact native identifiers are preserved.

Apple supports HEVC alpha and ProRes codecs, including ProRes RAW on supported systems. Codec support is queried from the connected output. TIFF and DICOM remain valid observed photo containers, while RAW DNG and Apple ProRAW remain available through supported photo outputs.

AVFoundation metadata includes bodies, animal heads, and salient objects as well as faces and barcodes. These types remain available through Apple's native metadata identifiers and availability checks.

Prepared photo settings, photo lifecycle callbacks, depth filtering/conversion, buffer rotation, preview-sized output, deferred start, low-light boost, smooth autofocus, native session listeners, and custom output hooks have native implementations and remain supported. Geometry types retain their existing camera/view coordinate semantics. Seconds remain `Double`, matching `TimeInterval` and `CMTime.seconds`.

## Retained negotiation limitation

Depth resolution biases influence capture-format selection, but the resolver still selects the first supported depth format within the chosen capture format. This audit does not redesign depth-format ranking. Camera hardware, connected outputs, and system conditions still determine which negotiated configurations can run.

## Integration with parallel work

The SwiftUI and optional-module tasks can continue using direct initializers and the static `VisionCamera`/`FrameConverter` namespaces. No factory or compatibility aliases are added.

The current [SwiftUI PR #3](https://github.com/margelo/VisionCamera/pull/3) needs `AVCaptureDevice.TorchMode` in `Camera+configuration.swift`, `CameraCoordinator.swift`, and `CameraViewOptions.swift`. Its `CameraSession+setOutputOrientation.swift` must set orientation only on writable photo/video/frame/depth outputs; `any CameraOutput` exposes an observation, and preview/metadata orientation is read-only. Shared session and preview configuration methods now throw. SwiftUI controls also need native permission/control enum cases and the narrowed metering/torch API. A GPU module must request exact `PixelFormat` values and use native SIMD matrices or `getPixelBuffer()`. Metadata integrations use `AVMetadataObject.ObjectType`. Custom native outputs can throw from `configure(config:)`. Recording integrations use `AVVideoCodecType`, `setVideoCodec(_:)`, and the backend-specific file-type initializer. Native location metadata remains unchanged. SwiftUI previews read `outputOrientation`; they cannot assign an orientation that the preview ignores. Controls that set explicit lens, exposure, or white-balance values use the new custom-value capabilities rather than the current-value locking capabilities.

## Validation

Validated locally with Xcode 26.6 and the iOS 26.5 SDK/runtime. CI remains pinned to Xcode 26.2.

| Check | Result |
| --- | --- |
| Strict `swift-format` for Sources, Tests, example, and Package.swift | Passed |
| `swift package dump-package` and SPM device Release build | Passed, signing disabled |
| SPM simulator XCTest suite | 73 tests, zero failures |
| `rbenv exec bundle exec pod lib lint VisionCamera.podspec --platforms=ios --verbose` | Passed, including 73 tests |
| CocoaPods example Release builds | Device and simulator passed, signing disabled |
| CocoaPods strict DocC and coverage script | Passed, 851/851 public declarations documented |
| SPM strict DocC and coverage script | Passed, 851/851 public declarations documented |
| Maintained Swift guide/README examples | All 42 pages type-checked against the built public module with the iOS 15.1 target |
| Public consumer tests | Compiled and ran with ordinary `import VisionCamera` |
| Removed-symbol search and `git diff --check` | Passed |

The snippet check concatenated Swift blocks from each maintained DocC page and type-checked them with `swiftc -typecheck -swift-version 5 -target arm64-apple-ios15.1`, using the built module. The README package-manifest fragment was checked through the package manifest; its app example was checked separately.

No physical-device capture was performed. Camera hardware, RAW/ProRAW/ProRes RAW, HDR, depth, external-camera operation, multi-camera capture, and live synchronized delivery still require hardware verification. The tests exercise native value conversion, unsupported settings, buffer lifetime, defaults, negotiation decisions, and callbacks without claiming those hardware results. Local linker diagnostics about the installed Metal toolchain and simulator TCC diagnostics did not fail builds or tests.

## Primary Apple references

- [AVCaptureDevice.DeviceType](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype-swift.struct)
- [Core Video pixel formats](https://developer.apple.com/documentation/corevideo/pixel-format-identifiers)
- [AVDepthData](https://developer.apple.com/documentation/avfoundation/avdepthdata)
- [AVCaptureColorSpace](https://developer.apple.com/documentation/avfoundation/avcapturecolorspace)
- [Native frame-output settings](https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput/videosettings)
- [Available frame-output pixel formats](https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput/availablevideopixelformattypes)
- [Depth format conversion](https://developer.apple.com/documentation/avfoundation/avdepthdata/converting(todepthdatatype:))
- [Capture color-space selection](https://developer.apple.com/documentation/avfoundation/avcapturedevice/activecolorspace)
- [Highest photo-quality capability](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format/ishighestphotoqualitysupported)
- [Extended dynamic range](https://developer.apple.com/documentation/avfoundation/avcapturedevice/isvideohdrenabled)
- [Video stabilization modes](https://developer.apple.com/documentation/avfoundation/avcapturevideostabilizationmode)
- [Dolby Vision on Apple platforms](https://developer.apple.com/av-foundation/Incorporating-HDR-video-with-Dolby-Vision-into-your-apps.pdf)
- [AVCaptureMovieFileOutput](https://developer.apple.com/documentation/avfoundation/avcapturemoviefileoutput)
- [Capturing still and Live Photos](https://developer.apple.com/documentation/avfoundation/capturing-still-and-live-photos)
- [Depth data delivery](https://developer.apple.com/documentation/avfoundation/avcapturephotooutput/isdepthdatadeliveryenabled)
- [Camera calibration data delivery](https://developer.apple.com/documentation/avfoundation/avcapturephotosettings/iscameracalibrationdatadeliveryenabled)
- [AVVideoCodecType](https://developer.apple.com/documentation/avfoundation/avvideocodectype)
- [Codec-specific recording settings](https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput/recommendedvideosettings(forvideocodectype:assetwriteroutputfiletype:))
- [Metadata types](https://developer.apple.com/documentation/avfoundation/metadata-types)
- [Face roll angle validity](https://developer.apple.com/documentation/avfoundation/avmetadatafaceobject/rollangle)
- [AVCaptureDataOutputSynchronizer](https://developer.apple.com/documentation/avfoundation/avcapturedataoutputsynchronizer)
- [AVCameraCalibrationData](https://developer.apple.com/documentation/avfoundation/avcameracalibrationdata)
- [Native torch modes](https://developer.apple.com/documentation/avfoundation/avcapturedevice/torchmode-swift.enum)
- [Torch illumination levels](https://developer.apple.com/documentation/avfoundation/avcapturedevice/settorchmodeon(level:))
- [Focus point of interest](https://developer.apple.com/documentation/avfoundation/avcapturedevice/focuspointofinterest)
- [Native focus rectangles](https://developer.apple.com/documentation/avfoundation/avcapturedevice/focusrectofinterest)
- [Custom lens-position support](https://developer.apple.com/documentation/avfoundation/avcapturedevice/islockingfocuswithcustomlenspositionsupported)
- [Custom white-balance gain support](https://developer.apple.com/documentation/avfoundation/avcapturedevice/islockingwhitebalancewithcustomdevicegainssupported)
- [Active low-light boost](https://developer.apple.com/documentation/avfoundation/avcapturedevice/islowlightboostenabled)
- [Mixing the capture audio session](https://developer.apple.com/documentation/avfoundation/avcapturesession/configuresapplicationaudiosessiontomixwithothers)
- [Metadata coordinate transformations](https://developer.apple.com/documentation/avfoundation/avcaptureoutput/transformedmetadataobject(for:connection:))
