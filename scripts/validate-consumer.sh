#!/bin/bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"
manager="${1:-spm}"
selection="${2:-combined}"
consumer="$repository_root/build/consumers/$manager/$selection"
derived_data="$repository_root/build/consumer-products/$manager/$selection"
bundle exec ruby scripts/create-consumer.rb "$manager" "$selection"
if [ "$manager" = pods ]; then
  (cd "$consumer" && bundle exec pod install)
  project=(-workspace "$consumer/OptionalModules.xcworkspace")
else
  project=(-project "$consumer/OptionalModules.xcodeproj")
fi

simulator_id="${SIMULATOR_ID:-}"
if [ -z "$simulator_id" ]; then
  simulator_id=$(xcrun simctl list devices available --json | ruby -rjson -e '
    devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
    puts devices.find { |device| device["deviceTypeIdentifier"].include?("iPhone") }&.fetch("udid")
  ')
fi
test -n "$simulator_id"
xcodebuild "${project[@]}" -scheme OptionalModules -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath "$derived_data/device" \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild "${project[@]}" -scheme OptionalModules -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$derived_data/simulator" \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild "${project[@]}" -scheme OptionalModules -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$derived_data/simulator" \
  CODE_SIGNING_ALLOWED=NO build-for-testing
# Launch the installed test products without resolving the local package graph again.
test_run=$(find "$derived_data/simulator/Build/Products" -maxdepth 1 -name 'OptionalModules_*.xctestrun' -print -quit)
test -n "$test_run"
xcodebuild -xctestrun "$test_run" \
  -destination "platform=iOS Simulator,id=$simulator_id" -destination-timeout 120 \
  -parallel-testing-enabled NO \
  -resultBundlePath "$derived_data/tests-$(date +%s).xcresult" \
  CODE_SIGNING_ALLOWED=NO test-without-building

if [ "$selection" = core ]; then
  executable="$derived_data/device/Build/Products/Release-iphoneos/OptionalModules.app/OptionalModules"
  xcrun nm "$executable" > "$derived_data/core-symbols.txt"
  if rg 'CLLocationManager|requestWhenInUseAuthorization|requestAlwaysAuthorization|VisionCameraLocation|GPUResizer|BarcodeScanner' "$derived_data/core-symbols.txt"; then
    echo 'Core consumer contains optional implementation symbols.' >&2
    exit 1
  fi
  if find "$derived_data/device/Build/Products/Release-iphoneos" -name 'VisionCameraResizer*' -o -name 'VisionCameraBarcodeScanner*' -o -name 'VisionCameraLocation*' | rg .; then
    echo 'Core consumer built optional products.' >&2
    exit 1
  fi
fi
