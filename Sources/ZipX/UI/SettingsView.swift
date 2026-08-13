import AppKit
import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var updater = UpdateChecker.shared
    @AppStorage("zipx.saveBesideSource") private var saveBesideSource = true
    @AppStorage("zipx.extractBesideArchive") private var extractBesideArchive = true
    @AppStorage("zipx.autoCheckUpdate") private var autoCheckUpdate = true
    @State private var installingRAR = false
    @State private var installMessage: String?

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
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZipXBrandMark(size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ZipX")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("v\(ZipXBrand.version) · \(archLabel)")
                        .font(.system(size: 12))
                        .foregroundStyle(ZipXBrand.inkMuted)
                }
                Spacer()
                Button("完成") { isPresented = false }
                    .buttonStyle(ZipXPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }

            simpleRow("官网", ZipXBrand.websiteHost) {
                NSWorkspace.shared.open(ZipXBrand.websiteURL)
            }
            simpleRow("GitHub", ZipXBrand.githubHost) {
                NSWorkspace.shared.open(ZipXBrand.githubURL)
            }

            Divider().background(ZipXBrand.line)

            Toggle("启动时检查更新", isOn: $autoCheckUpdate)
            Toggle("压缩到原目录", isOn: $saveBesideSource)
            Toggle("解压到包旁", isOn: $extractBesideArchive)

            HStack {
                Button {
                    updater.check(manual: true)
                } label: {
                    if updater.isChecking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("检查更新")
                    }
                }
                .buttonStyle(ZipXGhostButtonStyle())

                if let msg = updater.lastMessage {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundStyle(ZipXBrand.inkMuted)
                        .lineLimit(1)
                }
            }

            Divider().background(ZipXBrand.line)

            Text(formatLine)
                .font(.system(size: 12))
                .foregroundStyle(ZipXBrand.inkMuted)

            if !ArchiveService.canCreateRAR() {
                HStack(spacing: 8) {
                    Button(installingRAR ? "安装中…" : "安装 RAR 压缩组件") {
                        installingRAR = true
                        installMessage = nil
                        Task {
                            let msg = await ToolSupport.installRARCreator()
                            await MainActor.run {
                                installMessage = msg
                                installingRAR = false
                            }
                        }
                    }
                    .buttonStyle(ZipXGhostButtonStyle())
                    .disabled(installingRAR)

                    Button("下载") { ToolSupport.openRARLabDownload() }
                        .buttonStyle(.borderless)
                        .foregroundStyle(ZipXBrand.extractTone)
                }
                if let installMessage {
                    Text(installMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(ZipXBrand.inkMuted)
                        .lineLimit(3)
                }
            }
        }
        .padding(22)
        .frame(width: 420)
        .background(ZipXBrand.canvas)
        .preferredColorScheme(.light)
        .tint(ZipXBrand.accentColor)
    }

    private var formatLine: String {
        let zip = "ZIP ✓"
        let seven = ArchiveService.find7z() != nil ? "7Z ✓" : "7Z ✗"
        let rarX = ArchiveService.canExtractRAR() ? "RAR解压 ✓" : "RAR解压 ✗"
        let rarC = ArchiveService.canCreateRAR() ? "RAR压缩 ✓" : "RAR压缩 需组件"
        return "\(zip)  ·  \(seven)  ·  \(rarX)  ·  \(rarC)"
    }

    private func simpleRow(_ title: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(ZipXBrand.ink)
                Spacer()
                Text(value)
                    .font(.system(size: 12))
                    .foregroundStyle(ZipXBrand.extractTone)
                    .lineLimit(1)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
