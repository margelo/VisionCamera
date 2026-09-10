# ``Frame``

## Topics

### Creating a frame

- ``init(buffer:metadata:)``

### Reading frame metadata

- ``width``
- ``height``
- ``bytesPerRow``
- ``timestamp``
- ``orientation``
- ``isMirrored``
- ``pixelFormat``
- ``metadata``
- ``cameraIntrinsicMatrix``

### Accessing pixel data

- ``isPlanar``
- ``hasPixelBuffer``
- ``pixelBuffer``
- ``sampleBuffer``
- ``getPixelBuffer()``
- ``getPlanes()``
- ``withUnsafeBytes(_:)``

### Managing frame lifetime

- ``isValid``
- ``memorySize``
- ``dispose()``

### Converting coordinates

- ``convertCameraPointToFramePoint(cameraPoint:)``
- ``convertFramePointToCameraPoint(framePoint:)``
