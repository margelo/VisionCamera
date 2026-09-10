# ``VisionCameraResizer``

Resize camera frames into RGB or BGR tensors with Metal.

## Overview

Add the `VisionCameraResizer` Swift package product or CocoaPod to your app, then import `VisionCameraResizer`.
The module supports iOS 15.1 and later. It depends on `VisionCamera`, Core Video, and Metal.
Core-only apps do not compile or link the resizer or its shaders.

``GPUResizer`` accepts full-range, 8-bit, bi-planar NV12 pixel buffers. It preserves the original resizer's bilinear sampling,
BT.601 full-range conversion, centered crop, letterbox, stretch, clockwise rotation, and source-axis mirroring.
It produces three channels, ordered as RGB or BGR, with interleaved or planar storage.
The scalar encodings are UInt8, Int8, Float16, and Float32.

## Topics

### Resize camera frames

- <doc:ResizeFrames>
- ``GPUResizer``
- ``GPUResizeResult``

### Configure output tensors

- ``ResizerOptions``
- ``ResizerChannelOrder``
- ``ResizerDataType``
- ``ResizerPixelLayout``
- ``ResizerScaleMode``
- ``GPUResizerError``

### Understand ownership and source compatibility

- <doc:BufferOwnership>
- <doc:SourceCompatibility>
