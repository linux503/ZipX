import AppKit
import SwiftUI

enum ZipXBrand {
    static let name = "ZipX"
    static let tagline = "压缩、解压、预览，样样好用"
    static let version = "1.2.1"
    static let build = "6"

    static let websiteURL = URL(string: "https://linux503.github.io/ZipX/")!
    static let githubURL = URL(string: "https://github.com/linux503/ZipX")!
    static let updateFeedURL = URL(string: "https://linux503.github.io/ZipX/version.json")!
    static let githubLatestAPI = URL(string: "https://api.github.com/repos/linux503/ZipX/releases/latest")!

    /// 界面展示用（去掉协议）
    static var websiteHost: String { "linux503.github.io/ZipX" }
    static var githubHost: String { "github.com/linux503/ZipX" }

    /// 浅色纸感底 + 珊瑚主色（避开紫 / 奶油陶土）
    static let canvas = Color(red: 0.945, green: 0.953, blue: 0.965)
    static let surface = Color.white
    static let ink = Color(red: 0.12, green: 0.15, blue: 0.20)
    static let inkMuted = Color(red: 0.42, green: 0.47, blue: 0.55)
    static let line = Color(red: 0.82, green: 0.85, blue: 0.89)
    static let accent = NSColor(calibratedRed: 0.95, green: 0.35, blue: 0.22, alpha: 1) // coral
    static let accentColor = Color(nsColor: accent)
    static let compressTone = Color(red: 0.95, green: 0.35, blue: 0.22)
    static let extractTone = Color(red: 0.15, green: 0.45, blue: 0.72)
    static let previewTone = Color(red: 0.12, green: 0.55, blue: 0.48)
}

struct ZipXBrandMark: View {
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let image = Self.logoImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.55, blue: 0.38),
                                    ZipXBrand.accentColor,
                                    Color(red: 0.90, green: 0.22, blue: 0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .shadow(color: ZipXBrand.accentColor.opacity(0.28), radius: 8, y: 3)
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
