#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build-universal"
APP_DIR="$ROOT/dist/ZipX.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
MIN_OS="13.0"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
BIN_NAME="ZipX"

echo "==> ZipX Universal Build"
echo "    SDK: $SDK"
echo "    Root: $ROOT"

rm -rf "$BUILD_DIR" "$APP_DIR"
mkdir -p "$BUILD_DIR" "$MACOS" "$RESOURCES"

SOURCES=()
while IFS= read -r f; do
  SOURCES+=("$f")
done < <(find "$ROOT/Sources/ZipX" -name '*.swift' | sort)

build_arch_main() {
  local arch="$1"
  local out="$BUILD_DIR/${BIN_NAME}-$arch"
  echo "==> Compiling ${arch}..."
  xcrun swiftc \
    -sdk "$SDK" \
    -target "${arch}-apple-macos${MIN_OS}" \
    -O \
    -swift-version 5 \
    -strict-concurrency=minimal \
    -framework AppKit \
    -framework SwiftUI \
    -framework UniformTypeIdentifiers \
    -o "$out" \
    "${SOURCES[@]}"
}

HOST_ARCH="$(uname -m)"
build_arch_main "$HOST_ARCH"

OTHER_ARCH=""
if [[ "$HOST_ARCH" == "arm64" ]]; then
  OTHER_ARCH="x86_64"
elif [[ "$HOST_ARCH" == "x86_64" ]]; then
  OTHER_ARCH="arm64"
fi

UNIVERSAL_OUT="$BUILD_DIR/$BIN_NAME"
if [[ -n "$OTHER_ARCH" ]]; then
  if ! build_arch_main "$OTHER_ARCH"; then
    echo "!! ERROR: $OTHER_ARCH 交叉编译失败，Universal 构建中止"
    exit 1
  fi
  echo "==> Creating universal binary (arm64 + x86_64)..."
  lipo -create \
    "$BUILD_DIR/${BIN_NAME}-arm64" \
    "$BUILD_DIR/${BIN_NAME}-x86_64" \
    -output "$UNIVERSAL_OUT"
else
  cp "$BUILD_DIR/${BIN_NAME}-$HOST_ARCH" "$UNIVERSAL_OUT"
fi

cp "$UNIVERSAL_OUT" "$MACOS/$BIN_NAME"
chmod +x "$MACOS/$BIN_NAME"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
echo -n "APPLZIPX" > "$CONTENTS/PkgInfo"

if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi
if [[ -f "$ROOT/Resources/ZipX-logo.png" ]]; then
  sips -z 512 512 "$ROOT/Resources/ZipX-logo.png" --out "$RESOURCES/ZipX-logo.png" >/dev/null
fi

# 内置归档引擎（7zz Universal + unar + rar/unrar）
"$ROOT/Scripts/bundle_rar.sh"
if [[ -d "$ROOT/Resources/bin" ]]; then
  echo "==> Bundling archive engines..."
  mkdir -p "$RESOURCES/bin"
  cp -f "$ROOT/Resources/bin/"* "$RESOURCES/bin/" 2>/dev/null || true
  chmod +x "$RESOURCES/bin/"* 2>/dev/null || true
  xattr -cr "$RESOURCES/bin" 2>/dev/null || true
  ls -lh "$RESOURCES/bin" || true
fi

xattr -cr "$APP_DIR" 2>/dev/null || true

if command -v codesign >/dev/null; then
  echo "==> Ad-hoc codesign..."
  # 先签内置二进制，再签 App
  if [[ -d "$RESOURCES/bin" ]]; then
    for bin in "$RESOURCES/bin/"*; do
      [[ -f "$bin" && -x "$bin" ]] || continue
      codesign --force --sign - --identifier "app.zipx.mac.bin.$(basename "$bin")" "$bin" 2>/dev/null || true
    done
  fi
  codesign --force --deep --sign - \
    --identifier "app.zipx.mac" \
    --entitlements "$ROOT/Resources/ZipX.entitlements" \
    "$APP_DIR" || true
fi

echo "==> Done: $APP_DIR"
lipo -info "$MACOS/$BIN_NAME" || true
echo ""
echo "运行： open \"$APP_DIR\""
echo "安装： ./Scripts/install.sh"
echo "DMG：  ./Scripts/make_dmg.sh"
