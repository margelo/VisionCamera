#!/bin/bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"
bundle exec ruby scripts/create-consumer.rb pods combined
consumer="$repository_root/build/consumers/pods/combined"
(cd "$consumer" && bundle exec pod install)
derived_data="$repository_root/build/optional-documentation"
for module in VisionCameraResizer VisionCameraBarcodeScanner VisionCameraLocation; do
  xcodebuild docbuild \
    -workspace "$consumer/OptionalModules.xcworkspace" -scheme "$module" \
    -configuration Release -destination 'generic/platform=iOS' \
    -derivedDataPath "$derived_data" CODE_SIGNING_ALLOWED=NO \
    DOCC_EXTRACT_EXTENSION_SYMBOLS=YES \
    OTHER_DOCC_FLAGS='--warnings-as-errors --experimental-documentation-coverage --coverage-summary-level brief'
done
bundle exec ruby scripts/check-documentation.rb "$derived_data"
