# ``Photo``

## Topics

### Creating a photo

- ``init(photo:metadata:containerFormat:)``

### Reading photo metadata

- ``width``
- ``height``
- ``dimensions``
- ``timestamp``
- ``orientation``
- ``isMirrored``
- ``isRaw``
- ``containerFormat``
- ``metadata``
- ``depth``
- ``calibrationData``

### Creating an image

- ``image()``

### Saving a photo

- ``encodedData()``
- ``write(to:options:)``
- ``writeToTemporaryFile()``

### Accessing native data

- ``photo``
- ``pixelBuffer``
- ``withUnsafeBytes(_:)``
