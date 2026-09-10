# ``VisionCameraLocation``

Foreground location updates and explicit permission requests for apps that geotag camera captures.

## Overview

Select the `VisionCameraLocation` product in Swift Package Manager, or install the
`VisionCameraLocation` CocoaPod. Both expose `import VisionCameraLocation` and require iOS 15.1.
The module depends on Apple's Core Location framework and has no dependency on VisionCamera core.

Use ``LocationManager`` when your app needs to collect locations. VisionCamera core
already accepts caller-supplied `CLLocation` values for photo and video metadata.
Passing one of those values does not require this optional module.

## Topics

### Collecting locations

- <doc:LocationUpdates>
- <doc:LocationPrivacy>
- ``LocationManager``
- ``LocationManagerOptions``
- ``LocationAccuracy``
- ``LocationManagerError``
