#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/dist/ZipX.app"
DEST="/Applications/ZipX.app"

if [[ ! -f "$SRC/Contents/MacOS/ZipX" ]]; then
  "$ROOT/Scripts/build.sh"
fi

echo "==> 安装 ZipX → /Applications"
killall ZipX 2>/dev/null || true
sleep 0.2
rm -rf "$DEST"
ditto "$SRC" "$DEST"
chmod +x "$DEST/Contents/MacOS/ZipX"
xattr -cr "$DEST" 2>/dev/null || true
codesign --force --deep --sign - \
  --identifier "app.zipx.mac" \
  --entitlements "$ROOT/Resources/ZipX.entitlements" \
  "$DEST" || true

echo "✅ 已安装: $DEST"
open "$DEST"
