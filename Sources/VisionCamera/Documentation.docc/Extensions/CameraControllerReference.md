# ``CameraController``

## Topics

### Configuring camera behavior

- ``configure(config:)``
- ``device``
- ``isConnected``
- ``isSuspended``

### Zooming

- ``zoom``
- ``minZoom``
- ``maxZoom``
- ``displayableZoomFactor``
- ``setZoom(zoom:)``
- ``startZoomAnimation(zoom:rate:)``
- ``cancelZoomAnimation()``

### Focusing

- ``focusMode``
- ``lensPosition``
- ``isSmoothAutoFocusEnabled``
- ``focusTo(point:options:)``
- ``resetFocus()``
- ``setFocusLocked(lensPosition:)``
- ``lockCurrentFocus()``
- ``addSubjectAreaChangedListener(onSubjectAreaChanged:)``

### Adjusting exposure

- ``exposureMode``
- ``exposureBias``
- ``setExposureBias(exposure:)``
- ``exposureDuration``
- ``minExposureDuration``
- ``maxExposureDuration``
- ``activeMaxExposureDuration``
- ``iso``
- ``minISO``
- ``maxISO``
- ``setExposureLocked(duration:iso:)``
- ``lockCurrentExposure()``
- ``isLowLightBoostEnabled``

### Adjusting white balance

- ``whiteBalanceMode``
- ``whiteBalanceGains``
- ``convertWhiteBalanceTemperatureAndTintValues(whiteBalanceTemperatureAndTint:)``
- ``setWhiteBalanceLocked(whiteBalanceGains:)``
- ``lockCurrentWhiteBalance()``

### Controlling the torch

- ``torchMode``
- ``torchLevel``
- ``setTorchMode(mode:)``
- ``setTorchModeOn(level:)``

### Accessing native controls

- ``captureDevice``
- ``queue``
- ``isDistortionCorrectionEnabled``
