import AppKit
import SwiftUI

struct AboutView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var updater = UpdateChecker.shared

    private var archLabel: String {
        "Universal · Apple Silicon + Intel"
    }

    var body: some View {
        VStack(spacing: 18) {
            ZipXBrandMark(size: 78)
            VStack(spacing: 6) {
                Text(ZipXBrand.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(ZipXBrand.ink)
                Text(ZipXBrand.tagline)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ZipXBrand.inkMuted)
                Text("版本 \(ZipXBrand.version)（\(ZipXBrand.build)）· \(archLabel)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }

            VStack(spacing: 8) {
                linkRow(title: "官网", value: ZipXBrand.websiteHost) {
                    NSWorkspace.shared.open(ZipXBrand.websiteURL)
                }
                linkRow(title: "GitHub", value: ZipXBrand.githubHost) {
                    NSWorkspace.shared.open(ZipXBrand.githubURL)
                }
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }

            Button("关闭") { isPresented = false }
                .keyboardShortcut(.cancelAction)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ZipXBrand.inkMuted)
                .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 440)
        .background(ZipXBrand.canvas)
        .preferredColorScheme(.light)
    }

    private func linkRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ZipXBrand.inkMuted)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(ZipXBrand.extractTone)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(ZipXBrand.surface)
            .clipShape(RoundedRectangle(cornerRadius: ZipXBrand.radiusSM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ZipXBrand.radiusSM, style: .continuous)
                    .stroke(ZipXBrand.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
