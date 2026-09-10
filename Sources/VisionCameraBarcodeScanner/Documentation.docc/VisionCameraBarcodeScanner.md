# ``VisionCameraBarcodeScanner``

Scan camera Frames and still images with Apple's on-device Vision machine learning detector.

## Overview

This optional module requires iOS 16 or later. It uses Vision request revision 3 on iOS 16 and revision 4 on iOS 17 and later. VisionCamera core continues to support iOS 15.1.

Create a ``BarcodeScanner``, then call its synchronous scan methods from a background queue or a `FrameOutput` callback. Each scanner processes one image at a time. Results retain their decoded values and geometry independently of the source image.

The backend differs from the React Native package's Google ML Kit scanner. Read <doc:BarcodeBackend> before migrating format filters or payload handling.

## Topics

### Scan barcodes

- <doc:ScanningBarcodes>
- <doc:BarcodeBackend>
- ``BarcodeScanner``
- ``BarcodeScannerOptions``
- ``BarcodeScannerError``
- ``Barcode``
