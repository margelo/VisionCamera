# Run the optional module example

This UIKit app processes Camera frames with the GPU resizer and Vision barcode scanner, and starts foreground location updates after you tap **Enable location**. It processes at most one frame per second for readable status updates. Production apps can choose their own frame budget.

Use Xcode 26.2 or later, the repository's Ruby version, and `bundle install`. Generate a project with either package manager:

```sh
rbenv exec bundle exec ruby scripts/create-consumer.rb spm combined
open build/consumers/spm/combined/OptionalModules.xcodeproj
```

For CocoaPods:

```sh
rbenv exec bundle exec ruby scripts/create-consumer.rb pods combined
cd build/consumers/pods/combined
rbenv exec bundle exec pod install
open OptionalModules.xcworkspace
```

Select the **OptionalModules** scheme. Choose a signing team and enable signing in the generated app target to run on your iPhone. Generated projects disable signing for CI by default. A simulator runs the synthetic tests; use a device for a live Camera and GPU timing. Location tests use an injected manager and never change the simulator's permission state.

Replace `combined` with `core`, `resizer`, `barcode`, or `location` to generate an independently selected consumer. The location consumer has no dependency on core. Barcode and combined consumers require iOS 16. The other selections require iOS 15.1.

Run public-consumer tests and simulator/device Release builds with:

```sh
SIMULATOR_ID=<simulator-udid> rbenv exec ruby -e 'exec("bash", "scripts/validate-consumer.sh", "spm", "combined")'
SIMULATOR_ID=<simulator-udid> rbenv exec ruby -e 'exec("bash", "scripts/validate-consumer.sh", "pods", "combined")'
```

Projects and build results go into ignored `build/` directories. The maintained [core example](../Example/) stays independent of optional modules.

Some iOS simulator runtimes cannot execute Vision's ML barcode detector correctly. Detection tests first run an independent native Vision probe. If that probe cannot decode a known QR, the test reports a skip. Scanner failures still fail when the native probe works. Run `scripts/test-barcode-host.sh` to exercise the same maintained scanner's decoding and coordinate behavior on macOS, and use an iPhone to validate camera images and detection performance. The host package is a test harness; the distributed package remains iOS-only.
