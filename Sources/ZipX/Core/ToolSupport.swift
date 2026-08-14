import AppKit
import Darwin
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
        else { parts.append("RAR 压缩不可用") }
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

    /// 用户目录下的可选 RAR 组件（RARLab 官方包）
    static func userRARBinDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("ZipX/bin", isDirectory: true)
    }

    /// 确保内置二进制可执行（清隔离属性）
    static func prepareBundledTools() {
        let names = ["7zz", "7z", "unar", "lsar", "unrar", "rar"]
        for name in names {
            guard let url = bundledURL(name) else { continue }
            prepareExecutable(at: url.path)
        }
        for name in ["rar", "unrar"] {
            let path = userRARBinDirectory().appendingPathComponent(name).path
            if FileManager.default.fileExists(atPath: path) {
                prepareExecutable(at: path)
            }
        }
    }

    /// 安装 RAR 创建组件：优先 RARLab 直链（无需 brew / Xcode），brew 仅作备选
    @discardableResult
    static func installRARCreator() async -> String {
        await Task.detached(priority: .userInitiated) {
            prepareBundledTools()
            if ArchiveService.canCreateRAR() {
                return "RAR 创建组件已就绪"
            }

            do {
                try installFromRARLab()
                prepareBundledTools()
                if ArchiveService.canCreateRAR() {
                    return "已从 RARLab 安装 RAR 组件"
                }
            } catch {
                let hint = friendlyInstallError(error)
                if let brewMsg = tryInstallViaBrew() {
                    return brewMsg
                }
                return hint
            }

            if let brewMsg = tryInstallViaBrew() {
                return brewMsg
            }
            return "安装未完成。可重试，或前往 RARLab 手动下载 macOS 版 RAR。"
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

    // MARK: - RARLab direct install

    private static func installFromRARLab() throws {
        let binDir = userRARBinDirectory()
        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)

        let downloadURL = rarLabDownloadURL()
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("zipx-rar-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let archive = tmp.appendingPathComponent("rar.tgz")
        try downloadFile(from: downloadURL, to: archive)

        let extractDir = tmp.appendingPathComponent("extract")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
        try run("/usr/bin/tar", ["-xzf", archive.path, "-C", extractDir.path])

        guard let rarSrc = findExtractedBinary(named: "rar", under: extractDir),
              let unrarSrc = findExtractedBinary(named: "unrar", under: extractDir) else {
            throw ArchiveError.toolFailed("解压 RAR 包后未找到 rar / unrar")
        }

        let rarDst = binDir.appendingPathComponent("rar")
        let unrarDst = binDir.appendingPathComponent("unrar")
        if FileManager.default.fileExists(atPath: rarDst.path) {
            try FileManager.default.removeItem(at: rarDst)
        }
        if FileManager.default.fileExists(atPath: unrarDst.path) {
            try FileManager.default.removeItem(at: unrarDst)
        }
        try FileManager.default.copyItem(at: rarSrc, to: rarDst)
        try FileManager.default.copyItem(at: unrarSrc, to: unrarDst)
        prepareExecutable(at: rarDst.path)
        prepareExecutable(at: unrarDst.path)
    }

    private static func rarLabDownloadURL() -> URL {
        if cpuIsArm64 {
            return URL(string: "https://www.rarlab.com/rar/rarmacos-arm-723.tar.gz")!
        }
        return URL(string: "https://www.rarlab.com/rar/rarmacos-x64-723.tar.gz")!
    }

    private static var cpuIsArm64: Bool {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let rc = sysctlbyname("hw.optional.arm64", &value, &size, nil, 0)
        return rc == 0 && value == 1
    }

    private static func downloadFile(from url: URL, to destination: URL) throws {
        let sema = DispatchSemaphore(value: 0)
        var requestError: Error?
        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            defer { sema.signal() }
            if let error {
                requestError = error
                return
            }
            guard let tempURL else {
                requestError = ArchiveError.toolFailed("下载 RAR 组件失败")
                return
            }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)
            } catch {
                requestError = error
            }
        }
        task.resume()
        sema.wait()
        if let requestError { throw requestError }
    }

    private static func findExtractedBinary(named name: String, under root: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }
        for case let url as URL in enumerator {
            if url.lastPathComponent == name, FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    // MARK: - Brew fallback

    private static func tryInstallViaBrew() -> String? {
        let brew = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
        guard let brew else { return nil }
        do {
            try run(brew, ["install", "--cask", "rar"])
            prepareBundledTools()
            if ArchiveService.canCreateRAR() {
                return "已通过 Homebrew 安装 RAR 组件"
            }
            return "brew 已执行，但未检测到 rar。请重开 ZipX 后再试。"
        } catch {
            return friendlyInstallError(error)
        }
    }

    private static func friendlyInstallError(_ error: Error) -> String {
        let raw = error.localizedDescription
        if raw.localizedCaseInsensitiveContains("xcode license")
            || raw.localizedCaseInsensitiveContains("agreed to the xcode") {
            return """
            自动安装失败：尚未接受 Xcode 许可协议。
            请在「终端」执行：
            sudo xcodebuild -license accept
            然后回到 ZipX 重试；或直接点「下载」从 RARLab 安装。
            """
        }
        if raw.localizedCaseInsensitiveContains("homebrew") && raw.localizedCaseInsensitiveContains("not found") {
            return "未检测到 Homebrew。ZipX 会尝试从 RARLab 直接下载；若仍失败，请点「下载」手动安装。"
        }
        return "自动安装失败：\(raw)\n也可手动从 RARLab 下载 macOS 版 RAR。"
    }

    // MARK: - Helpers

    private static func bundledURL(_ name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "bin"),
           FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        if let root = Bundle.main.resourceURL {
            let url = root.appendingPathComponent("bin/\(name)")
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    private static func prepareExecutable(at path: String) {
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        p.arguments = ["-cr", path]
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        try? p.run()
        p.waitUntilExit()
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
