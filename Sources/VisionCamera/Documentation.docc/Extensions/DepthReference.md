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
- ``isDepthDataFiltered``
- ``pixelFormat``
- ``depthDataAccuracy``
- ``depthDataQuality``
- ``availableDepthPixelFormats``
- ``cameraCalibrationData``
- ``metadata``

### Accessing depth samples

- ``depthData``
- ``pixelBuffer``
- ``getDepthData()``
- ``getPixelBuffer()``
- ``getNativeBuffer()``
- ``withUnsafeBytes(_:)``
- ``toFrame()``

### Managing depth lifetime

- ``isValid``
- ``memorySize``
- ``dispose()``

### Converting and rotating depth

- ``convert(pixelFormat:)``
- ``convertAsync(pixelFormat:)``
- ``rotate(orientation:isMirrored:)``
- ``rotateAsync(orientation:isMirrored:)``

### Converting coordinates

- ``convertCameraPointToDepthPoint(cameraPoint:)``
- ``convertDepthPointToCameraPoint(depthPoint:)``
