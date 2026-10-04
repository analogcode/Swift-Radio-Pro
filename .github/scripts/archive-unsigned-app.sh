#!/bin/bash
set -euo pipefail

archive_path="${1:?archive path required}"
version_name="${2:?marketing version required}"
build_number="${3:?build number required}"

# Releases and PR validation use this same command so a tag's version reaches the binary.
xcodebuild archive -project SwiftRadio.xcodeproj -scheme SwiftRadio \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  -onlyUsePackageVersionsFromResolvedFile -jobs 2 \
  CODE_SIGNING_ALLOWED=NO \
  MARKETING_VERSION="$version_name" CURRENT_PROJECT_VERSION="$build_number"
