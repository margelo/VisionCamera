# ``Photo``

## Topics

### Creating a photo

- ``init(photo:metadata:containerFormat:)``

### Reading photo metadata

- ``width``
- ``height``
- ``size``
- ``timestamp``
- ``orientation``
- ``isMirrored``
- ``isRawPhoto``
- ``containerFormat``
- ``metadata``
- ``depth``
- ``calibrationData``
- ``memorySize``

### Creating an image

- ``toImage()``
- ``toImageAsync()``

### Saving a photo

- ``getFileData()``
- ``getFileDataAsync()``
- ``saveToFileAsync(path:)``
- ``saveToTemporaryFileAsync()``

### Accessing native data

- ``photo``
- ``pixelBuffer``
- ``hasPixelBuffer``
- ``getPixelBuffer()``
- ``withUnsafeBytes(_:)``
