import AppKit
import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var updater = UpdateChecker.shared
    @AppStorage("zipx.saveBesideSource") private var saveBesideSource = true
    @AppStorage("zipx.extractBesideArchive") private var extractBesideArchive = true
    @AppStorage("zipx.autoCheckUpdate") private var autoCheckUpdate = true

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
        VStack(spacing: 0) {
            header
            Divider().background(ZipXBrand.line)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    aboutBlock
                    linksBlock
                    updateBlock
                    defaultsBlock
                    toolsBlock
                }
                .padding(22)
            }
            Divider().background(ZipXBrand.line)
            HStack {
                Spacer()
                Button("完成") { isPresented = false }
                    .buttonStyle(ZipXPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 480, height: 560)
        .background(ZipXBrand.canvas)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZipXBrandMark(size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("设置")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ZipXBrand.ink)
                Text("版本 \(ZipXBrand.version)（\(ZipXBrand.build)）· \(archLabel)")
                    .font(.system(size: 11))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ZipXBrand.inkMuted.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var aboutBlock: some View {
        settingsSection("关于 ZipX") {
            Text(ZipXBrand.tagline)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ZipXBrand.ink)
            Text("先选文件，再选压缩或解压。支持 ZIP / 7Z / RAR、加密、分卷、固实与预览。")
                .font(.system(size: 12))
                .foregroundStyle(ZipXBrand.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var linksBlock: some View {
        settingsSection("官网与源码") {
            linkRow(
                title: "官网",
                subtitle: ZipXBrand.websiteHost,
                icon: "globe",
                tint: ZipXBrand.compressTone
            ) {
                NSWorkspace.shared.open(ZipXBrand.websiteURL)
            }
            Divider().background(ZipXBrand.line)
            linkRow(
                title: "GitHub",
                subtitle: ZipXBrand.githubHost,
                icon: "chevron.left.forwardslash.chevron.right",
                tint: ZipXBrand.extractTone
            ) {
                NSWorkspace.shared.open(ZipXBrand.githubURL)
            }
            Text("点击即可在浏览器打开上述地址")
                .font(.system(size: 11))
                .foregroundStyle(ZipXBrand.inkMuted)
                .padding(.top, 4)
        }
    }

    private var updateBlock: some View {
        settingsSection("更新") {
            Toggle("启动时自动检查更新", isOn: $autoCheckUpdate)
                .toggleStyle(.switch)
                .tint(ZipXBrand.accentColor)

            HStack {
                Button {
                    updater.check(manual: true)
                } label: {
                    if updater.isChecking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("立即检查更新")
                    }
                }
                .buttonStyle(ZipXGhostButtonStyle())

                if let msg = updater.lastMessage {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundStyle(ZipXBrand.inkMuted)
                        .lineLimit(2)
                }
            }
        }
    }

    private var defaultsBlock: some View {
        settingsSection("默认行为") {
            Toggle("压缩默认保存到原目录", isOn: $saveBesideSource)
                .toggleStyle(.switch)
                .tint(ZipXBrand.accentColor)
            Toggle("解压默认放到压缩包旁", isOn: $extractBesideArchive)
                .toggleStyle(.switch)
                .tint(ZipXBrand.accentColor)
        }
    }

    private var toolsBlock: some View {
        settingsSection("格式支持") {
            toolStatus("ZIP", ok: true, detail: "系统自带，开箱即用")
            toolStatus("7Z", ok: ArchiveService.find7z() != nil, detail: ArchiveService.find7z() != nil ? "已检测到 7z" : "未安装 · brew install p7zip")
            toolStatus("RAR 解压", ok: ArchiveService.canExtractRAR(), detail: ArchiveService.canExtractRAR() ? "可用" : "未安装 · brew install p7zip / unar")
            toolStatus("RAR 压缩", ok: ArchiveService.canCreateRAR(), detail: ArchiveService.canCreateRAR() ? "可用" : "需安装 · brew install --cask rar")
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(ZipXBrand.inkMuted)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ZipXBrand.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ZipXBrand.line, lineWidth: 1)
            )
        }
    }

    private func linkRow(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ZipXBrand.ink)
                    Text(subtitle)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(ZipXBrand.extractTone)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toolStatus(_ name: String, ok: Bool, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(ok ? ZipXBrand.previewTone : ZipXBrand.compressTone.opacity(0.7))
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ZipXBrand.ink)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
            Spacer()
            Text(ok ? "就绪" : "缺少")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ok ? ZipXBrand.previewTone : ZipXBrand.inkMuted)
        }
    }
}
