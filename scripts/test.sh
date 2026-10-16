#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
run_id="$(date +%Y%m%d-%H%M%S)-$$"
architecture="$(uname -m)"
for language in en zh-Hant; do
  region=US
  [[ "$language" == zh-Hant ]] && region=TW
  xcodebuild -project 'Table Tool.xcodeproj' -scheme 'Table Tool' \
    -configuration Debug -destination "platform=macOS,arch=$architecture" \
    -derivedDataPath build/DerivedData -testLanguage "$language" -testRegion "$region" \
    -resultBundlePath "build/Tests-$language-$run_id.xcresult" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- test
done
