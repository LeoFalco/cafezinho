#!/bin/sh
# Installs the latest Cafezinho release into /Applications and opens it.
# curl -fsSL https://raw.githubusercontent.com/LeoFalco/cafezinho/main/install.sh | sh
set -e

URL=https://github.com/LeoFalco/cafezinho/releases/latest/download/Cafezinho.zip
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $URL"
curl -fsSL "$URL" -o "$TMP/Cafezinho.zip"
ditto -x -k "$TMP/Cafezinho.zip" "$TMP"

pkill -x Cafezinho || true
while pgrep -x Cafezinho >/dev/null; do sleep 0.1; done
rm -rf /Applications/Cafezinho.app
mv "$TMP/Cafezinho.app" /Applications/
# The app is ad-hoc signed, so Gatekeeper would block it if it carried the quarantine flag.
xattr -dr com.apple.quarantine /Applications/Cafezinho.app 2>/dev/null || true
open /Applications/Cafezinho.app
echo "Installed: /Applications/Cafezinho.app (look for the cup in the menu bar)"
