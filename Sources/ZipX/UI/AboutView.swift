import AppKit
import SwiftUI

struct AboutView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var updater = UpdateChecker.shared

    private var archLabel: String {
        "Universal · Apple Silicon + Intel"
    }

    var body: some View {
        VStack(spacing: 16) {
            ZipXBrandMark(size: 72)
            Text(ZipXBrand.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(ZipXBrand.ink)
            Text(ZipXBrand.tagline)
                .foregroundStyle(ZipXBrand.inkMuted)
            Text("版本 \(ZipXBrand.version)（\(ZipXBrand.build)）· \(archLabel)")
                .font(.caption)
                .foregroundStyle(ZipXBrand.inkMuted)

            VStack(spacing: 8) {
                Button {
                    NSWorkspace.shared.open(ZipXBrand.websiteURL)
                } label: {
                    HStack {
                        Text("官网")
                            .foregroundStyle(ZipXBrand.inkMuted)
                        Spacer()
                        Text(ZipXBrand.websiteHost)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(ZipXBrand.extractTone)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(ZipXBrand.inkMuted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ZipXBrand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(ZipXBrand.line, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    NSWorkspace.shared.open(ZipXBrand.githubURL)
                } label: {
                    HStack {
                        Text("GitHub")
                            .foregroundStyle(ZipXBrand.inkMuted)
                        Spacer()
                        Text(ZipXBrand.githubHost)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(ZipXBrand.extractTone)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(ZipXBrand.inkMuted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ZipXBrand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(ZipXBrand.line, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 360)

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
        .frame(width: 440)
        .background(ZipXBrand.canvas)
        .preferredColorScheme(.light)
    }
}
