#!/bin/sh
# Installs the latest Cafezinho release into /Applications and opens it.
# curl -fsSL https://raw.githubusercontent.com/LeoFalco/cafezinho/main/install.sh | sh
set -e

# Everything lives in main so a truncated `curl | sh` download runs nothing.
main() {
  url=https://github.com/LeoFalco/cafezinho/releases/latest/download/Cafezinho.zip
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT

  echo "Downloading $url"
  curl -fsSL "$url" -o "$tmp/Cafezinho.zip"
  ditto -x -k "$tmp/Cafezinho.zip" "$tmp"
  if [ ! -d "$tmp/Cafezinho.app" ]; then
    echo "Cafezinho.app not found in the release zip; nothing was changed." >&2
    exit 1
  fi

  pkill -x Cafezinho || true
  while pgrep -x Cafezinho >/dev/null; do sleep 0.1; done
  rm -rf /Applications/Cafezinho.app
  mv "$tmp/Cafezinho.app" /Applications/
  # The app is ad-hoc signed, so Gatekeeper would block it if it carried the quarantine flag.
  xattr -dr com.apple.quarantine /Applications/Cafezinho.app 2>/dev/null || true
  open /Applications/Cafezinho.app
  echo "Installed: /Applications/Cafezinho.app (look for the cup in the menu bar)"
}

main "$@"
