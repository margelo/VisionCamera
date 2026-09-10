# ``PreviewView``

## Topics

### Creating a preview view

- ``init(previewOutput:)``
- ``init(frame:)``
- ``init(coder:)``

### Configuring the preview

- ``previewOutput``
- ``resizeMode``
- ``gestureControllers``

### Observing preview events

- ``onPreviewStarted``
- ``onPreviewStopped``

### Converting coordinates

- ``convertCameraPointToViewPoint(cameraPoint:)``
- ``convertViewPointToCameraPoint(viewPoint:)``
- ``convertScannedObjectCoordinatesToViewCoordinates(scannedObject:)``
- ``meteringPoint(at:)``

### Laying out the preview

- ``layoutSubviews()``
