# ``VisionCamera/VisionCamera``

## Topics

### Requesting permissions

- ``cameraPermissionStatus``
- ``requestCameraPermission()``
- ``microphonePermissionStatus``
- ``requestMicrophonePermission()``

### Discovering cameras

- ``cameraDevices``
- ``getDefaultCamera(position:)``
- ``getCameraForId(id:)``
- ``userPreferredCamera``
- ``addOnCameraDevicesChangedListener(listener:)``
- ``discoverySession``

### Configuring cameras

- ``supportsMultiCamSessions``
- ``supportedMultiCamDeviceCombinations``
- ``resolveConstraints(device:outputConfigurations:constraints:requiresMultiCam:)``
