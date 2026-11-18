#!/bin/sh
# Uso: ./build.sh            gera build/Cafezinho.app
#      ./build.sh instalar   gera, copia para /Applications e abre
set -e
cd "$(dirname "$0")"

APP=build/Cafezinho.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -parse-as-library -swift-version 5 Sources/main.swift -o "$APP/Contents/MacOS/Cafezinho"
cp Info.plist "$APP/Contents/"
cp Cafezinho.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "Gerado: $APP"

if [ "$1" = "instalar" ]; then
  pkill -x Cafezinho || true
  rm -rf /Applications/Cafezinho.app
  cp -R "$APP" /Applications/
  open /Applications/Cafezinho.app
  echo "Instalado em /Applications/Cafezinho.app"
fi
