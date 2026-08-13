import AppKit
import SwiftUI

struct AboutView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var updater = UpdateChecker.shared

    private var archLabel: String {
        #if arch(arm64)
        "Apple Silicon"
        #elseif arch(x86_64)
        "Intel"
        #else
        "Universal"
        #endif
    }

    var body: some View {
        VStack(spacing: 18) {
            ZipXBrandMark(size: 72)
            Text(ZipXBrand.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(ZipXBrand.ink)
            Text(ZipXBrand.tagline)
                .foregroundStyle(ZipXBrand.inkMuted)
            Text("版本 \(ZipXBrand.version)（\(ZipXBrand.build)）· \(archLabel)")
                .font(.caption)
                .foregroundStyle(ZipXBrand.inkMuted)

            Text("先选文件，再选压缩或解压。支持加密、分卷、固实与预览。")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(ZipXBrand.inkMuted)
                .frame(maxWidth: 360)

            HStack(spacing: 12) {
                Button("官网") { NSWorkspace.shared.open(ZipXBrand.websiteURL) }
                    .buttonStyle(ZipXGhostButtonStyle())
                Button("GitHub") { NSWorkspace.shared.open(ZipXBrand.githubURL) }
                    .buttonStyle(ZipXGhostButtonStyle())
            }

            Button {
                updater.check(manual: true)
            } label: {
                if updater.isChecking {
                    ProgressView().controlSize(.small)
                } else {
                    Text("检查更新")
                }
            }
            .buttonStyle(ZipXPrimaryButtonStyle())

            if let msg = updater.lastMessage {
                Text(msg)
                    .font(.caption2)
                    .foregroundStyle(ZipXBrand.inkMuted)
            }

            Button("关闭") { isPresented = false }
                .keyboardShortcut(.cancelAction)
                .foregroundStyle(ZipXBrand.inkMuted)
        }
        .padding(32)
        .frame(width: 420)
        .background(ZipXBrand.canvas)
        .preferredColorScheme(.light)
    }
}
