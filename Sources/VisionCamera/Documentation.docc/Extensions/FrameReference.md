# ``Frame``

## Topics

### Creating a frame

- ``init(sampleBuffer:metadata:)``

### Reading frame metadata

- ``width``
- ``height``
- ``bytesPerRow``
- ``timestamp``
- ``orientation``
- ``isMirrored``
- ``pixelFormat``
- ``metadata``
- ``intrinsicMatrix``

### Accessing pixel data

- ``isPlanar``
- ``isValid``
- ``byteCount``
- ``pixelBuffer``
- ``sampleBuffer``
- ``planes``
- ``withUnsafeBytes(_:)``

### Converting coordinates

- ``point(fromCameraPoint:)``
- ``cameraPoint(from:)``
