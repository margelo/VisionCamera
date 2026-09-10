# Photo HDR

Understand high dynamic range photo processing and its control on iOS.

Photo HDR fuses multiple frames to capture photos with more detail in highlights and shadows. A typical pipeline merges underexposed, normally exposed, and overexposed frames as part of image processing.

## HDR photo processing on iOS

AVFoundation controls the processing applied to processed photo captures. This version of VisionCamera does not expose a manual photo HDR toggle on iOS. `CameraDevice.supportsPhotoHDR` returns `false`, and a ``PhotoHDRConstraint`` does not enable or disable HDR processing.

Capture a processed JPEG or HEIC photo through the regular <doc:PhotoOutputGuide>. Use <doc:PhotoQuality> to choose compression and quality prioritization. Those settings do not guarantee a particular HDR pipeline.

Video HDR has a separate configuration and is covered in <doc:VideoHDR>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/photo-hdr.mdx. -->
