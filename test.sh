#!/bin/sh
# Runs the test suite.
set -e
cd "$(dirname "$0")"

# Command Line Tools ship the Swift Testing macro plugin outside the default search path.
PLUGIN=/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
if [ "$(xcode-select -p)" = /Library/Developer/CommandLineTools ] && [ -d "$PLUGIN" ]; then
  exec swift test -Xswiftc -plugin-path -Xswiftc "$PLUGIN" "$@"
fi
exec swift test "$@"
