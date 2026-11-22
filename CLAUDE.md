# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Cafezinho is a macOS 13+ menu bar app (SwiftUI `MenuBarExtra`, SwiftPM, no Xcode project) that starts and stops `/usr/bin/caffeinate`. UI text, README and commit-facing docs are in Portuguese.

## Commands

```sh
./test.sh                               # all tests (wraps `swift test`)
./test.sh --filter buildsArgumentsFromOptions   # one test
./build.sh                              # build/Cafezinho.app (ad-hoc signed)
./build.sh install                      # build, replace /Applications/Cafezinho.app, open it
UNIVERSAL=1 VERSION=1.2.3 ./build.sh zip   # what CI does: universal binary + build/Cafezinho.zip
```

Always use `./test.sh` rather than bare `swift test`: with only Command Line Tools installed, it adds the Swift Testing macro plugin path that `swift test` can't find on its own.

## Architecture

- `Sources/CafezinhoCore/Caffeinator.swift` holds all logic: a `@MainActor ObservableObject` that owns one `caffeinate` `Process`. Option toggles persist to `UserDefaults` in `didSet` and, if active, restart the process keeping the remaining time. The `terminationHandler` only clears state if the finished process is still the current one (`self.process === finished`), so restarts don't race.
- `caffeinate` always gets `-w <app pid>` so it dies with the app. With no flags it would default to `-i`, so `start` refuses to run when no option is checked (`hasOption`).
- UserDefaults keys stay in Portuguese (`tela`, `inatividade`, `disco`, `carregador`) for compatibility with v1.0 preferences; don't rename them.
- `Sources/Cafezinho/CafezinhoApp.swift` is a thin SwiftUI menu over `Caffeinator`, plus "open at login" via `SMAppService.mainApp`.
- `Caffeinator` takes `defaults` and `executable` in its init so tests inject an isolated `UserDefaults` suite and a fake binary. Tests (Swift Testing, `.serialized`) launch the real `caffeinate`.
- The `.app` bundle is assembled by hand in `build.sh` from the SwiftPM binary, `Info.plist` and `Cafezinho.icns`. `tools/make-icon.swift` regenerates the icon PNG (convert with `sips`/`iconutil`).

## Release

CI (`.github/workflows/ci.yml`, macos-15) tests and builds on every push. Pushing a `vX.Y.Z` tag publishes a GitHub release with `Cafezinho.zip`, which `install.sh` downloads from `releases/latest`. The app is not notarized, so the installer strips the quarantine attribute.
