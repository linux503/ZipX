import AppKit
import SwiftUI

enum ZipXBrand {
    static let name = "ZipX"
    static let tagline = "压缩、解压、预览，样样好用"
    static let version = "1.2.4"
    static let build = "10"

    static let websiteURL = URL(string: "https://linux503.github.io/ZipX/")!
    static let githubURL = URL(string: "https://github.com/linux503/ZipX")!
    static let updateFeedURL = URL(string: "https://linux503.github.io/ZipX/version.json")!
    static let githubLatestAPI = URL(string: "https://api.github.com/repos/linux503/ZipX/releases/latest")!

    static var websiteHost: String { "linux503.github.io/ZipX" }
    static var githubHost: String { "github.com/linux503/ZipX" }

    /// 冷雾纸感底 + 珊瑚主色（与 App Icon 一致）
    static let canvas = Color(red: 0.941, green: 0.949, blue: 0.957)      // #F0F2F4
    static let surface = Color.white
    static let surfaceSoft = Color(red: 0.973, green: 0.976, blue: 0.980) // #F8F9FA
    static let ink = Color(red: 0.082, green: 0.106, blue: 0.137)         // #151B23
    static let inkMuted = Color(red: 0.380, green: 0.427, blue: 0.486)     // #616D7C
    static let line = Color(red: 0.875, green: 0.890, blue: 0.910)         // #DFE3E8
    static let accent = NSColor(calibratedRed: 0.910, green: 0.302, blue: 0.196, alpha: 1) // #E84D32
    static let accentColor = Color(nsColor: accent)
    static let accentSoft = Color(red: 1.0, green: 0.941, blue: 0.925)     // #FFF0EC
    static let compressTone = Color(red: 0.910, green: 0.302, blue: 0.196)
    static let extractTone = Color(red: 0.180, green: 0.420, blue: 0.580)  // #2E6B94
    static let previewTone = Color(red: 0.122, green: 0.478, blue: 0.420)  // #1F7A6B

    static let radiusLG: CGFloat = 18
    static let radiusMD: CGFloat = 14
    static let radiusSM: CGFloat = 10
}

struct ZipXBrandMark: View {
    var size: CGFloat = 40
    var showShadow: Bool = true

    var body: some View {
        Group {
            if let image = Self.logoImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.957, green: 0.431, blue: 0.227),
                                    ZipXBrand.accentColor,
                                    Color(red: 0.760, green: 0.173, blue: 0.157)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: size * 0.40, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
        .shadow(
            color: showShadow ? ZipXBrand.accentColor.opacity(0.22) : .clear,
            radius: showShadow ? 10 : 0,
            y: showShadow ? 4 : 0
        )
        .accessibilityLabel(ZipXBrand.name)
    }

    private static var logoImage: NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let url = Bundle.main.url(forResource: "ZipX-logo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return nil
    }
}

struct ZipXSectionLabel: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ZipXBrand.ink)
                .tracking(0.2)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
        }
    }
}
