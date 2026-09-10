# Source compatibility

The native module preserves the committed iOS resizer's pixel operations and output encodings.

## Source and license

The implementation adapts Marc Rousavy's `react-native-vision-camera-resizer` Swift code and Metal kernels
from revision `91bae1f08d549b50444ee16661dc4f4375cba0b6` of `margelo/react-native-vision-camera`.
The repository's MIT license applies. Source files retain Marc Rousavy's authorship and copyright notices.

The native API replaces the previous bridge wrappers with direct Swift initializers, native options, and ARC-owned output leases.
The original single reusable buffer becomes a bounded pool, with a default capacity of three independently retained results.

## Pixel behavior

Input is `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange`, often called full-range NV12.
Video-range NV12, BGRA, depth, and 10-bit buffers throw ``GPUResizerError/unsupportedPixelFormat(_:)``.
Pixel buffers need Metal compatibility. The resizer does not copy unsupported buffers into another format.

Conversion uses the original fixed BT.601 full-range coefficients and a chroma offset of 0.5.
The resizer clamps RGB channels to `0...1` and does not use color attachments to select another matrix.
An input marked BT.709 still uses the BT.601 coefficients, matching the source implementation.

``ResizerScaleMode/cover`` performs a centered crop on the longer source axis.
``ResizerScaleMode/contain`` adds black outside the fitted image.
``ResizerScaleMode/stretch`` scales each axis independently.
There is no arbitrary crop rectangle in the source API or this native API.

Orientation applies clockwise quarter-turns. `.right` produces a 90-degree clockwise rotation.
The shader flips the source's horizontal axis before rotation when `isMirrored` is true.
This preserves the source shader's actual behavior, including sideways frames.
Output dimensions always equal the configured dimensions. Scaling accounts for swapped input dimensions during quarter-turns.

UInt8 rounds normalized values times 255 to the nearest integer.
Int8 uses the same quantized value minus 128, so black padding is -128.
Float16 and Float32 store normalized values directly, so black padding is 0.
All outputs have three channels, tightly packed rows, and no alpha channel.

## Installed shaders

Swift Package Manager declares `Shaders` with `.process("Shaders")`, and Xcode compiles the Metal source into the target resource bundle.
The implementation uses `Bundle.module` to find that bundle.
The CocoaPod compiles the same Metal source in the `VisionCameraResizer` resource bundle.
The implementation searches the defining framework bundle and the app bundle for installed CocoaPods resources.
Both distributions load a precompiled `default.metallib`; runtime source compilation is not a fallback.

Apple documents [Swift package resource processing](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package)
and the requirement to retain [Core Video Metal textures](https://developer.apple.com/documentation/corevideo/cvmetaltexturecachecreatetexturefromimage(_:_:_:_:_:_:_:_:_:)) until GPU execution finishes.
