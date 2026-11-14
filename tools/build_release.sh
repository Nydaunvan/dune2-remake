#!/bin/bash
# Construit la version publiable : jeu exporté (Windows) + installateur autonome.
#   tools/build_release.sh            -> /tmp/build/release/TheBuildingOfADynasty-Setup.exe (+ jeu seul)
# Prérequis : Godot 4.7 avec ses modèles d'export, Go (compilation croisée), zip, export_presets.cfg.
set -euo pipefail
cd "$(dirname "$0")/.."
G=${GODOT:-/tmp/godot_bin/Godot_v4.7-stable_linux.x86_64}
OUT=${OUT:-/tmp/build/release}
VER=$(grep -m1 -o '\["[0-9][0-9.]*"' changelog_data.gd | tr -d '["')
echo "Version : $VER"
mkdir -p "$OUT" installer/work
rm -f installer/work/* "$OUT"/*
# 1. numéro de version dans l'export
sed -i "s/^application\/file_version=.*/application\/file_version=\"$VER.0\"/; s/^application\/product_version=.*/application\/product_version=\"$VER.0\"/" export_presets.cfg
# 2. export du jeu
"$G" --headless --path . --export-release "Windows Desktop" "$PWD/installer/work/TheBuildingOfADynasty.exe" 2>&1 | grep -v '^$' | tail -n 5
test -s installer/work/TheBuildingOfADynasty.exe
cd installer
export GOOS=windows GOARCH=amd64 CGO_ENABLED=0 GOFLAGS=-mod=mod
LD="-H=windowsgui -s -w -X main.version=$VER"
# 3. désinstalleur (même programme, sans charge utile)
: > payload.zip
go build -ldflags "$LD" -o work/uninstall.exe .
# 4. charge utile compressée : jeu + icône + désinstalleur
cp payload/icon.ico work/icon.ico
rm -f payload.zip
(cd work && zip -q -9 ../payload.zip TheBuildingOfADynasty.exe icon.ico uninstall.exe)
# 5. installateur
go build -ldflags "$LD" -o "$OUT/TheBuildingOfADynasty-Setup.exe" .
cp work/TheBuildingOfADynasty.exe "$OUT/TheBuildingOfADynasty.exe"
rm -f payload.zip
ls -la "$OUT"
