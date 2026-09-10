#!/bin/bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

# Use /VisionCamera for GitHub Pages, or / for a domain root or local preview.
hosting_base_path="${1:-/}"
derived_data="$repository_root/build/documentation"
archive="$derived_data/Build/Products/Release-iphoneos/VisionCamera/VisionCamera.doccarchive"
site="$repository_root/build/site"

(cd Example && bundle exec pod install)

xcodebuild docbuild \
  -workspace Example/VisionCameraExample.xcworkspace \
  -scheme VisionCamera \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  DOCC_EXTRACT_EXTENSION_SYMBOLS=YES \
  DOCC_HOSTING_BASE_PATH="$hosting_base_path" \
  OTHER_DOCC_FLAGS='--warnings-as-errors --experimental-documentation-coverage --coverage-summary-level brief'

bundle exec ruby scripts/check-documentation.rb "$derived_data"

# Keep the archive intact for Xcode, and give the hosted site a module landing URL.
mkdir -p "$site"
rsync -a --delete "$archive/" "$site/"
cat > "$site/index.html" <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="0; url=./documentation/visioncamera/">
    <title>VisionCamera Documentation</title>
  </head>
  <body><a href="./documentation/visioncamera/">VisionCamera Documentation</a></body>
</html>
HTML
touch "$site/.nojekyll"

printf '\nXcode archive: %s\nWebsite: %s\n' "$archive" "$site"
