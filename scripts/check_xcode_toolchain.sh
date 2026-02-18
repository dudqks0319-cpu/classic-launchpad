#!/usr/bin/env bash
set -euo pipefail

echo "== Xcode/Toolchain Check =="

echo "xcode-select path:"
xcode-select -p || true

echo
echo "swift version:"
swift --version || true

echo
echo "xcodebuild version:"
xcodebuild -version || true

echo
echo "If xcodebuild fails, run:"
echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
echo "  sudo xcodebuild -runFirstLaunch"
