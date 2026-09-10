# Location permission and app review

Keep location collection optional and describe its purpose only in apps that use it.

## Runtime requirements

Apple requires `NSLocationWhenInUseUsageDescription` when an app calls
[`requestWhenInUseAuthorization()`](https://developer.apple.com/documentation/corelocation/cllocationmanager/requestwheninuseauthorization()).
The app must be in the foreground for the system to show the prompt. The location
module validates that the purpose string exists and is nonempty before requesting
permission or starting updates. Starting without an existing grant throws instead
of letting Core Location request permission implicitly.

An app can construct ``LocationManager`` without prompting. Only an explicit call
to ``LocationManager/requestWhenInUseAuthorization()`` requests authorization.
Core-only camera views never construct this manager.

## App Review guidance

[Apple's App Review guidance](https://developer.apple.com/app-store/review/)
says apps that reference APIs accessing sensitive data should contain a purpose
string. In [Write clear purpose strings](https://developer.apple.com/videos/play/tech-talks/110152/),
the App Review team specifically discusses SDKs that reference protected-resource
APIs. Apple recommends removing those references from the app binary when the app
has no reason to access the resource. This guidance applies beyond the moment a
runtime prompt is shown.

Apple does not document an exhaustive rule for its binary scanner, linker dead
stripping, or every unused symbol. These sources do not establish that merely
linking `CoreLocation` or using the `CLLocation` value type always requires a
location usage description. They also do not guarantee that unused permission
request code will pass review without one.

`VisionCameraLocation` therefore owns all active `CLLocationManager` and location
authorization code in a separate product and CocoaPod. Core-only consumers retain
caller-supplied location metadata support without linking this implementation.
Select the optional module only for an app feature that uses location, and give
that feature a specific purpose string.

## Validation limits

Automated tests inject a location driver to verify explicit permission requests,
denial, revoked authorization, reduced accuracy, update lifetime, and errors.
They do not assert that a real user granted permission or that a device obtained
a GPS fix. A device run is needed to check prompts, foreground transitions, actual
accuracy, and power use. App Review acceptance cannot be verified by local tests.

Primary Apple sources checked on September 10, 2026.
