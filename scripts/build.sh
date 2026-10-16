#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# No third-party dependencies, credentials, or paid API calls are required.
architecture="${ARCHITECTURE:-arm64}"
case "$architecture" in arm64|x86_64) ;; *) echo 'ARCHITECTURE must be arm64 or x86_64' >&2; exit 2;; esac
derived="build/Release-$architecture"
xcodebuild -project 'Table Tool.xcodeproj' -scheme 'Table Tool' \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived" ARCHS="$architecture" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="${SIGN_IDENTITY:--}" build
app="$derived/Build/Products/Release/Table Tool Native.app"
/usr/bin/lipo -verify_arch "$architecture" "$app/Contents/MacOS/Table Tool Native"
/usr/bin/codesign --verify --deep --strict "$app"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
mkdir -p dist
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app" "dist/TableTool-Native-$version-$architecture.zip"
echo "Built $app"
echo "Packaged dist/TableTool-Native-$version-$architecture.zip"
echo 'Default signature: ad hoc. This archive is not Apple-notarized.'
