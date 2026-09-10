# ``CameraController``

## Topics

### Configuring camera behavior

- ``configure(_:)``
- ``device``
- ``isConnected``
- ``isSuspended``

### Zooming

- ``zoom``
- ``minZoom``
- ``maxZoom``
- ``displayableZoomFactor``
- ``setZoom(_:)``
- ``rampZoom(to:rate:)``
- ``cancelZoomRamp()``

### Focusing

- ``focusMode``
- ``lensPosition``
- ``isSmoothAutoFocusEnabled``
- ``focus(at:options:)``
- ``resetFocus()``
- ``lockFocus(at:)``
- ``lockCurrentFocus()``
- ``observeSubjectAreaChanges(_:)``

### Adjusting exposure

- ``exposureMode``
- ``exposureBias``
- ``setExposureBias(_:)``
- ``exposureDuration``
- ``minExposureDuration``
- ``maxExposureDuration``
- ``activeMaxExposureDuration``
- ``iso``
- ``minISO``
- ``maxISO``
- ``lockExposure(duration:iso:)``
- ``lockCurrentExposure()``
- ``isLowLightBoostEnabled``

### Adjusting white balance

- ``whiteBalanceMode``
- ``whiteBalanceGains``
- ``whiteBalanceGains(for:)``
- ``lockWhiteBalance(gains:)``
- ``lockCurrentWhiteBalance()``

### Controlling the torch

- ``torchMode``
- ``torchLevel``
- ``setTorchMode(_:)``
- ``setTorchModeOn(level:)``

### Accessing native controls

- ``captureDevice``
- ``queue``
- ``isDistortionCorrectionEnabled``
