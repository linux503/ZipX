<p align="center">
  <img src="docs/assets/logo.png" width="88" height="88" alt="ZipX" />
</p>

<h1 align="center">ZipX</h1>

<p align="center">
  <strong>Compress, extract, and preview — without the fuss</strong><br/>
  Pick files first, then compress, extract, or preview. 7-Zip and RAR are bundled. No Homebrew.
</p>

<p align="center">
  <a href="README.md">中文</a> · <b>English</b>
</p>

<p align="center">
  <a href="https://github.com/linux503/ZipX/releases/latest"><img src="https://img.shields.io/github/v/release/linux503/ZipX?style=flat-square&color=e84d32" alt="Release" /></a>
  <a href="https://github.com/linux503/ZipX/releases"><img src="https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square" alt="macOS 13+" /></a>
  <a href="https://github.com/linux503/ZipX/releases"><img src="https://img.shields.io/badge/Universal-arm64%20%2B%20x86__64-24292f?style=flat-square" alt="Universal" /></a>
</p>

<p align="center">
  <a href="https://linux503.github.io/ZipX/downloads/ZipX-1.2.5-Universal.dmg"><strong>Download DMG</strong></a>
  ·
  <a href="https://linux503.github.io/ZipX/">Website</a>
  ·
  <a href="https://github.com/linux503/ZipX/releases">All releases</a>
</p>

---

<p align="center">
  <img src="docs/assets/poster.jpg" alt="ZipX" width="880" />
</p>

---

## Features

A macOS archive tool with a clear workflow: select files, then choose what to do. One Universal installer for Apple Silicon and Intel.

| Capability | Details |
|------------|---------|
| **Compress / extract** | ZIP, 7Z, and RAR work out of the box (including RAR create and extract) |
| **Preview** | Browse archive contents without extracting |
| **Encrypt / split / solid** | Extra options stay folded away until you need them |
| **Bundled engines** | Universal `7zz`, plus `rar` / `unrar` — no Homebrew |
| **Updates** | Optional check on launch; manual check in Settings |

> The RAR engine follows the RARLab license. See `Resources/bin/RAR-LICENSE.txt`.

## Requirements

- macOS **13.0** or later
- Apple Silicon or Intel

## Install

1. Download [ZipX 1.2.5 Universal.dmg](https://linux503.github.io/ZipX/downloads/ZipX-1.2.5-Universal.dmg)
2. Open the DMG and drag **ZipX** into Applications
3. If Gatekeeper blocks it: System Settings → Privacy & Security → Open Anyway

### Build from source

```bash
git clone https://github.com/linux503/ZipX.git
cd ZipX
./Scripts/build.sh      # dist/ZipX.app (arm64 + x86_64)
./Scripts/install.sh    # Install to /Applications
./Scripts/make_dmg.sh   # Universal DMG, syncs docs/
```

| Path | Contents |
|------|----------|
| `Sources/ZipX/` | SwiftUI / AppKit source |
| `Resources/` | Info.plist, icons, bundled `bin/7zz` |
| `Scripts/` | Build / DMG / install |
| `docs/` | Website and downloads (GitHub Pages) |

Update feed: https://linux503.github.io/ZipX/version.json

## Other apps

| App | Role |
|-----|------|
| [Flare Pro](https://github.com/linux503/Flare) | Screenshot and recording |
| [MacText](https://github.com/linux503/MacText) | Native text editor |
| [SupTools](https://github.com/linux503/suptools) | Monitor, clean, uninstall |
| [FilesDesk](https://github.com/linux503/FilesDesk) | Batch rename |
| [MacFan](https://github.com/linux503/MacFan) | Fan control |

## License

- ZipX source as declared in this repository
- Bundled 7-Zip (`Resources/bin/7zz`) keeps its original license in `Resources/bin/`
- Issues: [GitHub Issues](https://github.com/linux503/ZipX/issues)
