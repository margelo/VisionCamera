# ``PreviewView``

## Topics

### Creating a preview view

- ``init(output:)``
- ``init(frame:)``
- ``init(coder:)``

### Configuring the preview

- ``output``
- ``resizeMode``
- ``gestureControllers``

### Observing preview events

- ``didStartPreview``
- ``didStopPreview``
- ``onInterfaceOrientationChanged``
- ``interfaceOrientation``

### Converting coordinates

- ``point(fromCameraPoint:)``
- ``cameraPoint(from:)``
- ``convertedToViewCoordinates(_:)``
- ``meteringPoint(at:)``

### Laying out the preview

- ``layoutSubviews()``
- ``didMoveToWindow()``
