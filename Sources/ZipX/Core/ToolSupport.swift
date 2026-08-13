import AppKit
import Foundation

/// 内置归档引擎状态与可选组件安装
enum ToolSupport {
    struct Status: Equatable {
        var sevenZip: Bool
        var unar: Bool
        var rarCreate: Bool
        var rarExtract: Bool

        var summary: String {
            var parts: [String] = []
            if sevenZip { parts.append("7-Zip 已内置") }
            if rarExtract { parts.append("RAR 解压可用") }
            if rarCreate { parts.append("RAR 压缩可用") }
            else { parts.append("RAR 压缩需额外组件") }
            return parts.joined(separator: " · ")
        }
    }

    static func currentStatus() -> Status {
        Status(
            sevenZip: ArchiveService.find7z() != nil,
            unar: ArchiveService.findUnar() != nil,
            rarCreate: ArchiveService.canCreateRAR(),
            rarExtract: ArchiveService.canExtractRAR()
        )
    }

    /// 确保内置二进制可执行（清隔离属性）
    static func prepareBundledTools() {
        let names = ["7zz", "7z", "unar", "lsar", "unrar", "rar"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "bin")
                    ?? Bundle.main.resourceURL?.appendingPathComponent("bin/\(name)")
            else { continue }
            let path = url.path
            guard FileManager.default.fileExists(atPath: path) else { continue }
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            p.arguments = ["-cr", path]
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try? p.run()
            p.waitUntilExit()
        }
    }

    /// 尝试通过 Homebrew 安装 RAR 创建组件（需本机有 brew）
    @discardableResult
    static func installRARCreator() async -> String {
        await Task.detached(priority: .userInitiated) {
            prepareBundledTools()
            if ArchiveService.canCreateRAR() {
                return "RAR 创建组件已就绪"
            }
            let brew = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
                .first { FileManager.default.isExecutableFile(atPath: $0) }
            guard let brew else {
                return "未检测到 Homebrew。可前往 https://www.rarlab.com/download.htm 下载 macOS 版 RAR，或先安装 brew 后再试。"
            }
            do {
                try run(brew, ["install", "--cask", "rar"])
                if ArchiveService.canCreateRAR() {
                    return "已安装 RAR 创建组件"
                }
                return "brew 已执行，但未检测到 rar。请重开 ZipX 后再试。"
            } catch {
                return "自动安装失败：\(error.localizedDescription)\n也可手动执行：brew install --cask rar"
            }
        }.value
    }

    static func openRARLabDownload() {
        if let url = URL(string: "https://www.rarlab.com/download.htm") {
            NSWorkspace.shared.open(url)
        }
    }

    static func openBrewInstallHint() {
        let script = """
        tell application "Terminal"
          activate
          do script "brew install --cask rar"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if error != nil {
                openRARLabDownload()
            }
        } else {
            openRARLabDownload()
        }
    }

    private static func run(_ launchPath: String, _ args: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        let err = Pipe()
        p.standardOutput = Pipe()
        p.standardError = err
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus != 0 {
            let data = err.fileHandleForReading.readDataToEndOfFile()
            let msg = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw ArchiveError.toolFailed(msg?.isEmpty == false ? msg! : "安装失败")
        }
    }
}
