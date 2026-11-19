#!/bin/sh
# Usage: ./build.sh           builds build/Cafezinho.app
#        ./build.sh install   builds, copies to /Applications and opens it
#        ./build.sh zip       builds and packs build/Cafezinho.zip
# Env:   UNIVERSAL=1          arm64 + x86_64 binary (needs Xcode)
#        VERSION=1.2.3        sets the version in Info.plist
set -e
cd "$(dirname "$0")"

case "$1" in
  "" | install | zip) ;;
  *) echo "unknown command: $1 (use install or zip)" >&2; exit 1 ;;
esac

ARCHS=""
[ "$UNIVERSAL" = 1 ] && ARCHS="--arch arm64 --arch x86_64"

# shellcheck disable=SC2086
swift build -c release --product Cafezinho $ARCHS
# shellcheck disable=SC2086
BIN="$(swift build -c release $ARCHS --show-bin-path)/Cafezinho"

APP=build/Cafezinho.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Cafezinho"
cp Info.plist "$APP/Contents/"
cp Cafezinho.icns "$APP/Contents/Resources/"
if [ -n "$VERSION" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" \
    -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
fi
codesign --force --sign - "$APP"
echo "Built: $APP"

case "$1" in
  install)
    pkill -x Cafezinho || true
    while pgrep -x Cafezinho >/dev/null; do sleep 0.1; done
    rm -rf /Applications/Cafezinho.app
    cp -R "$APP" /Applications/
    open /Applications/Cafezinho.app
    echo "Installed: /Applications/Cafezinho.app"
    ;;
  zip)
    ditto -c -k --norsrc --keepParent "$APP" build/Cafezinho.zip
    echo "Packed: build/Cafezinho.zip"
    ;;
esac
