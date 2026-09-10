# ``VisionCamera``

A Camera framework for iOS, with UIKit previews and native Swift access to photos, video, frames, and depth.

## Overview

VisionCamera builds on AVFoundation. Create a Camera session, connect the outputs your app needs, and use the returned controllers to adjust the Camera while it is running.

Start with <doc:GettingStarted> to install the library and display a preview. The guides cover capture, controls, processing, and the native types you can use to build your own Camera experience.

## Topics

### Getting started

- <doc:GettingStarted>
- <doc:CameraSessions>
- <doc:CameraDevices>
- <doc:CameraOutputs>
- <doc:Lifecycle>
- <doc:MultiCamera>

### Preview and controls

- <doc:PreviewOutputGuide>
- <doc:PreviewViewGuide>
- <doc:CameraControllerGuide>
- <doc:Zooming>
- <doc:ExposureBias>
- <doc:TapToFocus>
- <doc:LockingExposureFocusWhiteBalance>
- <doc:LowLightBoost>

### Configuration

- <doc:Constraints>
- <doc:FPS>
- <doc:Orientation>
- <doc:CoordinateSystems>
- <doc:Performance>

### Photo capture

- <doc:PhotoOutputGuide>
- <doc:PhotoGuide>
- <doc:PhotoCallbacks>
- <doc:PhotoQuality>
- <doc:PhotoHDR>
- <doc:RawPhotos>
- <doc:LocationMetadata>

### Video recording

- <doc:VideoOutputGuide>
- <doc:RecorderGuide>
- <doc:VideoHDR>
- <doc:VideoStabilization>

### Frames and depth

- <doc:FrameOutputGuide>
- <doc:FrameGuide>
- <doc:DepthOutputGuide>
- <doc:DepthFrame>
- <doc:PixelFormats>
- <doc:NativeBuffers>
- <doc:NativeProcessing>
- <doc:AsyncFrameProcessing>
- <doc:FrameRendererViewGuide>
- <doc:CustomOutputs>

### Object scanning

- <doc:ObjectOutputGuide>
- <doc:ScannedObjects>

### Camera APIs

- ``VisionCamera``
- ``CameraSession``
- ``CameraSessionConnection``
- ``CameraSessionConfiguration``
- ``CameraDevice``
- ``CameraController``
- ``CameraControllerConfiguration``
- ``ObservationToken``
- ``PermissionError``
- ``ConfigurationError``
- ``CameraSessionError``
- ``CameraControlError``
- ``CaptureError``
- ``RecordingError``
- ``MediaError``
- ``PreviewError``
- ``OrientationError``

### Output APIs

- ``CameraOutput``
- ``CameraOutputConfiguration``
- ``PreviewOutput``
- ``PhotoOutput``
- ``VideoOutput``
- ``MovieFileVideoOutput``
- ``VideoFrameOutput``
- ``FrameOutput``
- ``DepthOutput``
- ``ObjectOutput``
- ``OutputSynchronizer``
- ``SynchronizedFrameDrop``
- ``NativeCameraOutput``

### Capture and media APIs

- ``Photo``
- ``PhotoFile``
- ``CapturePhotoSettings``
- ``CapturePhotoCallbacks``
- ``Recorder``
- ``RecorderSettings``
- ``RecordingResult``
- ``RecordingStatus``
- ``Frame``
- ``FramePlane``
- ``Depth``
- ``CameraCalibrationData``
- ``MediaSampleMetadata``
- ``ScannedObject``
- ``ScannedCode``
- ``ScannedFace``

### UIKit and configuration APIs

- ``PreviewView``
- ``FrameRendererView``
- ``FrameRenderer``
- ``FrameConverter``
- ``ZoomGestureController``
- ``TapToFocusGestureController``
- ``OrientationManager``
- ``DeviceOrientationManager``
- ``InterfaceOrientationManager``
- ``CameraOrientation``
- ``Constraint``
- ``CameraSessionConfig``
- ``ResolutionRule``
- ``PixelFormat``

<!-- Guide source provenance is recorded in each article. The original guides are maintained in react-native-vision-camera/docs/content/docs. -->
