#!/bin/zsh
set -euo pipefail

# 安装 RAR / 7Z 解压与压缩依赖（可选）
echo "==> 安装 ZipX 归档工具依赖"

if ! command -v brew >/dev/null; then
  echo "未找到 Homebrew。请先安装：https://brew.sh"
  exit 1
fi

brew install p7zip unar || true
brew install --cask rar || true

echo ""
echo "检查："
for t in 7z 7zz unar unrar rar; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "  ✓ $t → $(command -v "$t")"
  else
    echo "  · $t 未找到"
  fi
done

echo ""
echo "说明："
echo "  · 解压 RAR：p7zip / unar / rar 任一即可"
echo "  · 创建 RAR：需要 rar（brew install --cask rar）"
