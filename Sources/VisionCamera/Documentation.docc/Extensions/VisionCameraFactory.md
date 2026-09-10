# ``VisionCamera/VisionCamera``

## Topics

### Creating a factory

- ``init()``

### Requesting permissions

- ``cameraPermissionStatus``
- ``requestCameraPermission()``
- ``microphonePermissionStatus``
- ``requestMicrophonePermission()``

### Discovering and configuring cameras

- ``createDeviceFactory()``
- ``supportsMultiCamSessions``
- ``createCameraSession(enableMultiCam:)``
- ``resolveConstraints(device:outputConfigurations:constraints:requiresMultiCam:)``

### Creating outputs

- ``createPreviewOutput()``
- ``createPhotoOutput(options:)``
- ``createVideoOutput(options:)``
- ``createFrameOutput(options:)``
- ``createDepthFrameOutput(options:)``
- ``createObjectOutput(options:)``
- ``createOutputSynchronizer(outputs:)``

### Working with previews and frames

- ``createZoomGestureController()``
- ``createTapToFocusGestureController()``
- ``createNormalizedMeteringPoint(x:y:size:)``
- ``createOrientationManager(orientationSource:)``
- ``createFrameRenderer()``
