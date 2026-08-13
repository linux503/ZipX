#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="$ROOT/dist/ZipX.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist" 2>/dev/null || echo "1.0.0")"
STAGE="$ROOT/.dmg-stage"
VOL_NAME="ZipX"
DMG_NAME="ZipX-${VERSION}-Universal.dmg"
OUT_DMG="$ROOT/dist/$DMG_NAME"
TMP_DMG="$ROOT/dist/.${DMG_NAME}.tmp.dmg"

echo "==> ZipX DMG 打包  v${VERSION}"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  "$ROOT/Scripts/build.sh"
fi

if [[ ! -d "$APP_SRC" ]]; then
  echo "!! 未找到 $APP_SRC"
  exit 1
fi

ARCHS="$(lipo -info "$APP_SRC/Contents/MacOS/ZipX" 2>/dev/null || true)"
echo "    $ARCHS"
echo "$ARCHS" | grep -q "arm64" || { echo "!! 缺少 arm64"; exit 1; }
echo "$ARCHS" | grep -q "x86_64" || { echo "!! 缺少 x86_64 (Intel)"; exit 1; }

rm -rf "$STAGE" "$TMP_DMG" "$OUT_DMG"
mkdir -p "$STAGE"
ditto "$APP_SRC" "$STAGE/ZipX.app"
ln -s /Applications "$STAGE/Applications"

cat > "$STAGE/安装说明.txt" <<EOF
ZipX ${VERSION}  ·  Universal (Apple Silicon + Intel)

安装
1. 将 ZipX 拖到 Applications
2. 从启动台或 /Applications 打开

功能
· 压缩 / 解压 / 预览
· 加密压缩、分卷压缩
· 固实压缩（7Z，需 brew install p7zip）
· 菜单：ZipX → 检查更新 / 关于（官网 · GitHub）

Bundle ID: app.zipx.mac
EOF

xattr -cr "$STAGE" 2>/dev/null || true

SIZE_MB="$(du -sm "$STAGE" | awk '{print int($1)+20}')"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" -ov -fs HFS+ -format UDRW -size "${SIZE_MB}m" "$TMP_DMG"

ATTACH_OUT="$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" 2>&1)" || true
MOUNT_DIR="$(print -r -- "$ATTACH_OUT" | grep -o '/Volumes/.*' | tail -1 | sed 's/[[:space:]]*$//')"
DEV_NODE="$(print -r -- "$ATTACH_OUT" | awk '/^\/dev\//{print $1; exit}')"

if [[ -z "${MOUNT_DIR:-}" || ! -d "$MOUNT_DIR" ]]; then
  rm -f "$TMP_DMG"
  hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" -ov -format UDZO -imagekey zlib-level=9 "$OUT_DMG"
else
  sleep 0.8
  osascript <<APPLESCRIPT || true
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 160, 840, 560}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set position of item "ZipX.app" of container window to {160, 180}
    set position of item "Applications" of container window to {480, 180}
    try
      set position of item "安装说明.txt" of container window to {320, 360}
    end try
    update without registering applications
    delay 0.6
    close
  end tell
end tell
APPLESCRIPT
  sync
  hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
  [[ -n "${DEV_NODE:-}" ]] && hdiutil detach "$DEV_NODE" -quiet 2>/dev/null || true
  hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUT_DMG"
  rm -f "$TMP_DMG"
fi

rm -rf "$STAGE"
codesign --force --sign - "$OUT_DMG" 2>/dev/null || true

# 同步官网 version.json 与下载目录
mkdir -p "$ROOT/docs/downloads"
cp "$OUT_DMG" "$ROOT/docs/downloads/"
SHA="$(shasum -a 256 "$OUT_DMG" | awk '{print $1}')"
cat > "$ROOT/docs/version.json" <<JSON
{
  "version": "${VERSION}",
  "notes": "ZipX ${VERSION} Universal：压缩 / 解压 / 预览 / 加密 / 分卷 / 固实；支持 Apple Silicon 与 Intel。",
  "url": "https://linux503.github.io/ZipX/",
  "dmg": "https://linux503.github.io/ZipX/downloads/${DMG_NAME}",
  "sha256": "${SHA}"
}
JSON

echo ""
echo "✅ DMG: $OUT_DMG"
ls -lh "$OUT_DMG"
lipo -info "$APP_SRC/Contents/MacOS/ZipX" || true
echo "SHA256: $SHA"
