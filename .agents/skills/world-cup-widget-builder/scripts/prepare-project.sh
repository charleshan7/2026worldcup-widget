#!/bin/sh
set -eu

skill_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
repo_root=$(CDPATH= cd -- "$skill_dir/../../.." && pwd)

cd "$repo_root"

if [ ! -f Config.local.xcconfig ]; then
  cp Config.local.xcconfig.example Config.local.xcconfig
  echo "Created Config.local.xcconfig. Add your own football-data.org token before running the app."
fi

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
  echo "Regenerated WorldCupWidget.xcodeproj."
else
  echo "XcodeGen is not installed. The checked-in Xcode project can still be opened directly."
fi
