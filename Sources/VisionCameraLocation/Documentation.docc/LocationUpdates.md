# Collecting foreground locations

Request permission when the user enables geotagging, then attach native locations to captures.

## Configure your app

Add a purpose string to the app's `Info.plist` that describes the feature people selected:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Add capture coordinates to the photos you choose to geotag.</string>
```

This module uses When In Use authorization. It does not request Always authorization,
temporary precise-location authorization, or background location updates. Do not add
Always usage descriptions or the `location` background mode for this module.

## Request permission and start updates

Create and retain the manager on the main actor. Construction configures Core Location
and observes authorization, but does not prompt or start location updates.

```swift
import CoreLocation
import VisionCameraLocation

@MainActor
final class GeotaggingController {
  let locationManager: LocationManager
  var location: CLLocation?
  var onError: ((Error) -> Void)?
  private var isEnabled = false

  init() throws {
    locationManager = try LocationManager(
      options: .init(accuracy: .balanced, distanceFilter: 10)
    )
    locationManager.onLocationChanged = { [weak self] location in
      self?.location = location
    }
    locationManager.onError = { [weak self] error in self?.onError?(error) }
    locationManager.onAuthorizationChanged = { [weak self] status, _ in
      guard let self, self.isEnabled else { return }
      if status == .authorizedWhenInUse || status == .authorizedAlways {
        do {
          try self.locationManager.startUpdating()
        } catch {
          self.onError?(error)
        }
      } else {
        self.location = nil
      }
    }
  }

  func enableGeotagging() throws {
    isEnabled = true
    switch locationManager.authorizationStatus {
    case .notDetermined:
      try locationManager.requestWhenInUseAuthorization()
    default:
      try locationManager.startUpdating()
    }
  }

  func disableGeotagging() {
    isEnabled = false
    locationManager.stopUpdating()
    location = nil
  }
}
```

Call `enableGeotagging()` from the user's action while the app is in the foreground.
The permission method returns before the user responds. An initial authorization
event may still report `.notDetermined`; that is not a denial. A denied request
cannot prompt again. Explain how the user can enable location in Settings if they
choose to use the feature later.

Stop updates when geotagging is disabled or the camera screen closes. Releasing
the manager schedules cleanup on the main queue and retains its native driver
until updates have stopped. Callbacks execute on the main actor. Apple
delivers [`CLLocationManager`](https://developer.apple.com/documentation/corelocation/cllocationmanager)
events on the creating thread's run loop, so this module creates the native manager
on the main thread. Move unrelated expensive work out of the callback.

## Use the location

The callback returns a native `CLLocation`. Retain it as long as you need it. Its
lifetime does not depend on the callback or manager. The manager uses the newest
valid location in each delegate batch and ignores queued updates after stopping.

`lastKnownLocation` can contain a cached, old value. Decide what age and horizontal
accuracy your feature accepts before attaching a location to a capture. Desired
accuracy does not promise a particular sensor, update frequency, or accuracy.
The user's reduced-accuracy choice also applies when you select `.high`.

For photos, assign the chosen value to `CapturePhotoSettings.location`. For videos,
assign it to `RecorderSettings.location`. Your app can use its own location provider
for these fields without installing `VisionCameraLocation`.

<!-- Adapted from react-native-vision-camera-location at 91bae1f08d549b50444ee16661dc4f4375cba0b6. Copyright (c) 2025 Marc Rousavy. MIT license. -->
