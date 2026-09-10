# ``Depth``

## Topics

### Creating depth data

- ``init(depthData:metadata:)``

### Reading depth metadata

- ``width``
- ``height``
- ``bytesPerRow``
- ``timestamp``
- ``orientation``
- ``isMirrored``
- ``isFiltered``
- ``pixelFormat``
- ``accuracy``
- ``quality``
- ``availablePixelFormats``
- ``calibrationData``
- ``metadata``

### Accessing depth samples

- ``depthData``
- ``pixelBuffer``
- ``byteCount``
- ``withUnsafeBytes(_:)``
- ``makeFrame()``

### Converting and rotating depth

- ``converted(to:)``
- ``rotated(by:mirrored:)``

### Converting coordinates

- ``point(fromCameraPoint:)``
- ``cameraPoint(from:)``
