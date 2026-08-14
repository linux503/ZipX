#!/bin/zsh
# 下载 RARLab 官方 macOS CLI，合成 Universal rar / unrar 到 Resources/bin/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$ROOT/Resources/bin"
ARM_URL="https://www.rarlab.com/rar/rarmacos-arm-723.tar.gz"
X64_URL="https://www.rarlab.com/rar/rarmacos-x64-723.tar.gz"
WORK="$ROOT/.cache/rar-bundle"
FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

mkdir -p "$BIN_DIR" "$WORK"

if [[ "$FORCE" != true && -f "$BIN_DIR/rar" && -f "$BIN_DIR/unrar" ]]; then
  if lipo -info "$BIN_DIR/rar" 2>/dev/null | rg -q 'x86_64.*arm64|arm64.*x86_64'; then
    echo "==> RAR 已内置（Universal），跳过"
    exit 0
  fi
fi

echo "==> 下载 RARLab macOS CLI…"
curl -fsSL "$ARM_URL" -o "$WORK/arm.tgz"
curl -fsSL "$X64_URL" -o "$WORK/x64.tgz"

rm -rf "$WORK/arm" "$WORK/x64"
mkdir -p "$WORK/arm" "$WORK/x64"
tar -xzf "$WORK/arm.tgz" -C "$WORK/arm"
tar -xzf "$WORK/x64.tgz" -C "$WORK/x64"

ARM_RAR="$(find "$WORK/arm" -name rar -type f | head -1)"
ARM_UNRAR="$(find "$WORK/arm" -name unrar -type f | head -1)"
X64_RAR="$(find "$WORK/x64" -name rar -type f | head -1)"
X64_UNRAR="$(find "$WORK/x64" -name unrar -type f | head -1)"

[[ -n "$ARM_RAR" && -n "$X64_RAR" && -n "$ARM_UNRAR" && -n "$X64_UNRAR" ]] || {
  echo "!! 未找到 rar / unrar 二进制"
  exit 1
}

echo "==> 合成 Universal rar / unrar…"
lipo -create "$ARM_RAR" "$X64_RAR" -output "$BIN_DIR/rar"
lipo -create "$ARM_UNRAR" "$X64_UNRAR" -output "$BIN_DIR/unrar"
chmod +x "$BIN_DIR/rar" "$BIN_DIR/unrar"
xattr -cr "$BIN_DIR/rar" "$BIN_DIR/unrar" 2>/dev/null || true

LICENSE="$(find "$WORK/arm" -name license.txt | head -1)"
if [[ -n "$LICENSE" ]]; then
  cp "$LICENSE" "$BIN_DIR/RAR-LICENSE.txt"
fi

echo "==> RAR 内置完成"
lipo -info "$BIN_DIR/rar"
lipo -info "$BIN_DIR/unrar"
ls -lh "$BIN_DIR/rar" "$BIN_DIR/unrar"
