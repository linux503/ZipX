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
        "Universal · Apple Silicon + Intel"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZipXBrandMark(size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(ZipXBrand.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ZipXBrand.ink)
                    Text("v\(ZipXBrand.version) · \(archLabel)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ZipXBrand.inkMuted)
                }
                Spacer()
                Button("完成") { isPresented = false }
                    .buttonStyle(ZipXPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 18)

            panel {
                VStack(spacing: 0) {
                    simpleRow("官网", ZipXBrand.websiteHost) {
                        NSWorkspace.shared.open(ZipXBrand.websiteURL)
                    }
                    Divider().overlay(ZipXBrand.line).padding(.leading, 4)
                    simpleRow("GitHub", ZipXBrand.githubHost) {
                        NSWorkspace.shared.open(ZipXBrand.githubURL)
                    }
                }
            }

            sectionTitle("偏好")
            panel {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("启动时检查更新", isOn: $autoCheckUpdate)
                    Toggle("压缩到原目录", isOn: $saveBesideSource)
                    Toggle("解压到包旁", isOn: $extractBesideArchive)

                    HStack(spacing: 10) {
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
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(ZipXBrand.inkMuted)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(14)
            }

            sectionTitle("格式支持")
            panel {
                VStack(alignment: .leading, spacing: 10) {
                    Text(formatLine)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ZipXBrand.inkMuted)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

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
                        .padding(.horizontal, 14)
                        .padding(.bottom, installMessage == nil ? 14 : 0)

                        if let installMessage {
                            Text(installMessage)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(ZipXBrand.inkMuted)
                                .lineLimit(3)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 14)
                        }
                    } else {
                        Color.clear.frame(height: 14)
                    }
                }
            }
        }
        .padding(22)
        .frame(width: 440)
        .background(ZipXBrand.canvas)
        .preferredColorScheme(.light)
        .tint(ZipXBrand.accentColor)
    }

    private var formatLine: String {
        let zip = "ZIP ✓"
        let seven = ArchiveService.find7z() != nil ? "7Z ✓" : "7Z ✗"
        let rarX = ArchiveService.canExtractRAR() ? "RAR解压 ✓" : "RAR解压 ✗"
        let rarC = ArchiveService.canCreateRAR() ? "RAR压缩 ✓" : "RAR压缩 ✗"
        return "\(zip)  ·  \(seven)  ·  \(rarX)  ·  \(rarC)"
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ZipXBrand.inkMuted)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(ZipXBrand.surface)
            .clipShape(RoundedRectangle(cornerRadius: ZipXBrand.radiusMD, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ZipXBrand.radiusMD, style: .continuous)
                    .stroke(ZipXBrand.line, lineWidth: 1)
            )
    }

    private func simpleRow(_ title: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ZipXBrand.ink)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ZipXBrand.extractTone)
                    .lineLimit(1)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
