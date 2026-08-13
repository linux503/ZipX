import Foundation

enum ArchiveError: LocalizedError {
    case emptySelection
    case toolFailed(String)
    case unsupported

    var errorDescription: String? {
        switch self {
        case .emptySelection: return "请先添加文件或文件夹"
        case .toolFailed(let msg): return msg
        case .unsupported: return "暂不支持该格式"
        }
    }
}

struct ArchiveEntry: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let size: Int64?
    let isDirectory: Bool
}

struct CompressOptions {
    var password: String = ""
    var splitMB: Int = 0
    var solid: Bool = false
    var format: CompressFormat = .zip
}

enum CompressFormat: String, CaseIterable, Identifiable {
    case zip = "ZIP"
    case sevenZ = "7Z"
    case rar = "RAR"

    var id: String { rawValue }
    var fileExtension: String {
        switch self {
        case .zip: return "zip"
        case .sevenZ: return "7z"
        case .rar: return "rar"
        }
    }
}

enum ArchiveService {
    static func isArchive(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        // multipart: .r00 .r01 … 也算
        if ext.range(of: #"^r\d{2}$"#, options: .regularExpression) != nil { return true }
        return ["zip", "7z", "rar", "tar", "gz", "tgz", "bz2", "xz", "cbz", "cbr"].contains(ext)
    }

    static func canCreateRAR() -> Bool { findRar() != nil }
    static func canExtractRAR() -> Bool {
        findUnrar() != nil || findRar() != nil || find7z() != nil || findUnar() != nil
    }

    static func compress(
        sources: [URL],
        destination: URL,
        options: CompressOptions,
        progress: (@Sendable (String) -> Void)? = nil
    ) async throws {
        guard !sources.isEmpty else { throw ArchiveError.emptySelection }
        try await Task.detached(priority: .userInitiated) {
            progress?("准备压缩…")
            switch options.format {
            case .zip:
                try Self.zipCompress(sources: sources, destination: destination, options: options, progress: progress)
            case .sevenZ:
                try Self.sevenZCompress(sources: sources, destination: destination, options: options, progress: progress)
            case .rar:
                try Self.rarCompress(sources: sources, destination: destination, options: options, progress: progress)
            }
            progress?("完成")
        }.value
    }

    static func extract(
        archive: URL,
        destination: URL,
        password: String = "",
        progress: (@Sendable (String) -> Void)? = nil
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            progress?("正在解压…")
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            let ext = archive.pathExtension.lowercased()
            let isRAR = ext == "rar" || ext == "cbr" || ext.range(of: #"^r\d{2}$"#, options: .regularExpression) != nil

            if isRAR {
                try Self.extractRAR(archive: archive, destination: destination, password: password, progress: progress)
            } else if ext == "7z" {
                try Self.run7z(["x", archive.path, "-o\(destination.path)", "-y"] + (password.isEmpty ? [] : ["-p\(password)"]))
            } else if ["tar", "gz", "tgz", "bz2", "xz"].contains(ext) {
                try Self.run("/usr/bin/tar", ["-xf", archive.path, "-C", destination.path])
            } else {
                do {
                    try Self.run("/usr/bin/ditto", ["-x", "-k", archive.path, destination.path])
                } catch {
                    var args = ["-o", archive.path, "-d", destination.path]
                    if !password.isEmpty {
                        args = ["-P", password, "-o", archive.path, "-d", destination.path]
                    }
                    try Self.run("/usr/bin/unzip", args)
                }
            }
            progress?("完成")
        }.value
    }

    static func listContents(of archive: URL, password: String = "") async throws -> [ArchiveEntry] {
        try await Task.detached(priority: .userInitiated) {
            let ext = archive.pathExtension.lowercased()
            let isRAR = ext == "rar" || ext == "cbr" || ext.range(of: #"^r\d{2}$"#, options: .regularExpression) != nil
            if isRAR {
                return try Self.listRAR(archive, password: password)
            }
            if ext == "7z" {
                return try Self.listVia7z(archive, password: password)
            }
            return try Self.listViaZipInfo(archive)
        }.value
    }

    // MARK: - RAR

    private static func rarCompress(
        sources: [URL],
        destination: URL,
        options: CompressOptions,
        progress: (@Sendable (String) -> Void)?
    ) throws {
        progress?("RAR 压缩中…")
        guard let bin = findRar() else {
            throw ArchiveError.toolFailed(
                """
                创建 RAR 需要 RARLab 命令行工具。
                请安装其一：
                · brew install --cask rar
                · 或从 https://www.rarlab.com/download.htm 下载 macOS 版
                """
            )
        }
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        // rar a [-hp密码] [-v100m] [-m5] [-s] archive.rar files…
        var args = ["a", "-ep1", "-r"]
        if options.solid { args.append("-s") }
        if options.splitMB > 0 { args.append("-v\(options.splitMB)m") }
        if !options.password.isEmpty {
            // -hp 同时加密文件名
            args.append("-hp\(options.password)")
        }
        args.append(destination.path)
        args += sources.map(\.path)
        try run(bin, args)
    }

    private static func extractRAR(
        archive: URL,
        destination: URL,
        password: String,
        progress: (@Sendable (String) -> Void)?
    ) throws {
        var errors: [String] = []

        // 1) unrar
        if let unrar = findUnrar() {
            progress?("unrar 解压中…")
            do {
                var args = ["x", "-o+", "-y"]
                if !password.isEmpty { args.append("-p\(password)") }
                else { args.append("-p-") }
                args += [archive.path, destination.path + "/"]
                try run(unrar, args)
                return
            } catch {
                errors.append("unrar: \(error.localizedDescription)")
            }
        }

        // 1b) rar（同套件）
        if let rar = findRar() {
            progress?("rar 解压中…")
            do {
                var args = ["x", "-o+", "-y"]
                if !password.isEmpty { args.append("-p\(password)") }
                else { args.append("-p-") }
                args += [archive.path, destination.path + "/"]
                try run(rar, args)
                return
            } catch {
                errors.append("rar: \(error.localizedDescription)")
            }
        }

        // 2) 7z / 7zz
        if let seven = find7z() {
            progress?("7z 解压 RAR…")
            do {
                var args = ["x", archive.path, "-o\(destination.path)", "-y"]
                if !password.isEmpty { args.append("-p\(password)") }
                try run(seven, args)
                return
            } catch {
                errors.append("7z: \(error.localizedDescription)")
            }
        }

        // 3) unar（The Unarchiver CLI）
        if let unar = findUnar() {
            progress?("unar 解压中…")
            do {
                var args = ["-force-overwrite", "-output-directory", destination.path]
                if !password.isEmpty { args += ["-password", password] }
                args.append(archive.path)
                try run(unar, args)
                return
            } catch {
                errors.append("unar: \(error.localizedDescription)")
            }
        }

        throw ArchiveError.toolFailed(
            """
            无法解压 RAR：未找到可用工具。
            请安装其一：
            · brew install p7zip
            · brew install unar
            · brew install --cask rar
            \(errors.isEmpty ? "" : "\n详情：\n" + errors.joined(separator: "\n"))
            """
        )
    }

    private static func listRAR(_ archive: URL, password: String) throws -> [ArchiveEntry] {
        if let unrar = findUnrar(), URL(fileURLWithPath: unrar).lastPathComponent != "rar" {
            var args = ["lb"]
            if !password.isEmpty { args.append("-p\(password)") }
            else { args.append("-p-") }
            args.append(archive.path)
            let output = try runCapture(unrar, args)
            return output.split(separator: "\n").map(String.init).filter { !$0.isEmpty }.map {
                ArchiveEntry(path: $0, size: nil, isDirectory: $0.hasSuffix("/"))
            }
        }
        if let rar = findRar() {
            var args = ["lb"]
            if !password.isEmpty { args.append("-p\(password)") }
            else { args.append("-p-") }
            args.append(archive.path)
            let output = try runCapture(rar, args)
            return output.split(separator: "\n").map(String.init)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("RAR ") && !$0.hasPrefix("Evaluation") }
                .map { ArchiveEntry(path: $0, size: nil, isDirectory: $0.hasSuffix("/")) }
        }
        if find7z() != nil {
            return try listVia7z(archive, password: password)
        }
        if let unar = findUnar() {
            let output = try runCapture(unar, ["-l", archive.path])
            return output.split(separator: "\n").map(String.init)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("(") && !$0.lowercased().contains("successfully") }
                .map { ArchiveEntry(path: $0, size: nil, isDirectory: $0.hasSuffix("/")) }
        }
        throw ArchiveError.toolFailed("无法预览 RAR。请安装：brew install p7zip 或 unar")
    }

    // MARK: - ZIP / 7Z

    private static func zipCompress(
        sources: [URL],
        destination: URL,
        options: CompressOptions,
        progress: (@Sendable (String) -> Void)?
    ) throws {
        if options.solid {
            if find7z() != nil {
                var o = options
                o.format = .sevenZ
                let dest7 = destination.deletingPathExtension().appendingPathExtension("7z")
                try sevenZCompress(sources: sources, destination: dest7, options: o, progress: progress)
                return
            }
        }

        if options.password.isEmpty && options.splitMB <= 0 && sources.count == 1, let only = sources.first {
            progress?("多线程压缩中…")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try run(
                "/usr/bin/ditto",
                ["-c", "-k", "--sequesterRsrc", "--keepParent", only.lastPathComponent, destination.path],
                cwd: only.deletingLastPathComponent().path
            )
            return
        }

        try zipCLI(sources: sources, destination: destination, options: options, progress: progress)
    }

    private static func zipCLI(
        sources: [URL],
        destination: URL,
        options: CompressOptions,
        progress: (@Sendable (String) -> Void)?
    ) throws {
        progress?("zip 压缩中…")
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        let staging = FileManager.default.temporaryDirectory.appendingPathComponent("zipx-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: staging) }
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        for src in sources {
            try FileManager.default.copyItem(at: src, to: staging.appendingPathComponent(src.lastPathComponent))
        }

        var args: [String] = ["-r", "-q"]
        if !options.password.isEmpty { args += ["-P", options.password] }
        if options.splitMB > 0 { args += ["-s", "\(options.splitMB)m"] }
        args.append(destination.path)
        args += sources.map(\.lastPathComponent)
        try run("/usr/bin/zip", args, cwd: staging.path)
    }

    private static func sevenZCompress(
        sources: [URL],
        destination: URL,
        options: CompressOptions,
        progress: (@Sendable (String) -> Void)?
    ) throws {
        progress?("7z 压缩中…")
        guard let bin = find7z() else {
            throw ArchiveError.toolFailed("未找到 7z。请执行：brew install p7zip")
        }
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        var args = ["a", "-t7z", destination.path, options.solid ? "-ms=on" : "-ms=off", "-mmt=on"]
        if options.splitMB > 0 { args.append("-v\(options.splitMB)m") }
        if !options.password.isEmpty {
            args.append("-p\(options.password)")
            args.append("-mhe=on")
        }
        args += sources.map(\.path)
        try run(bin, args)
    }

    private static func listViaZipInfo(_ archive: URL) throws -> [ArchiveEntry] {
        let output = try runCapture("/usr/bin/zipinfo", ["-1", archive.path])
        return output
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { ArchiveEntry(path: $0, size: nil, isDirectory: $0.hasSuffix("/")) }
    }

    private static func listVia7z(_ archive: URL, password: String) throws -> [ArchiveEntry] {
        guard let bin = find7z() else {
            throw ArchiveError.toolFailed("未找到 7z，无法预览此格式")
        }
        var args = ["l", "-slt", archive.path]
        if !password.isEmpty { args.append("-p\(password)") }
        let output = try runCapture(bin, args)
        var entries: [ArchiveEntry] = []
        var path: String?
        var size: Int64?
        var isDir = false
        for line in output.split(separator: "\n").map(String.init) {
            if line.hasPrefix("Path = ") {
                if let path, path != archive.lastPathComponent {
                    entries.append(ArchiveEntry(path: path, size: size, isDirectory: isDir))
                }
                path = String(line.dropFirst(7))
                size = nil
                isDir = false
            } else if line.hasPrefix("Size = ") {
                size = Int64(line.dropFirst(7))
            } else if line.hasPrefix("Attributes = ") {
                isDir = line.contains("D")
            }
        }
        if let path, path != archive.lastPathComponent, !path.isEmpty {
            entries.append(ArchiveEntry(path: path, size: size, isDirectory: isDir))
        }
        return entries
    }

    // MARK: - Tool discovery

    static func find7z() -> String? {
        findExecutable([
            "/opt/homebrew/bin/7z",
            "/usr/local/bin/7z",
            "/opt/homebrew/bin/7zz",
            "/usr/local/bin/7zz",
            "/opt/homebrew/bin/7za",
            "/usr/local/bin/7za",
            bundledTool("7zz"),
            bundledTool("7z")
        ])
    }

    static func findRar() -> String? {
        findExecutable([
            "/opt/homebrew/bin/rar",
            "/usr/local/bin/rar",
            "/usr/local/bin/rar/rar",
            "/Applications/RAR.app/Contents/MacOS/rar",
            bundledTool("rar")
        ])
    }

    static func findUnrar() -> String? {
        findExecutable([
            "/opt/homebrew/bin/unrar",
            "/usr/local/bin/unrar",
            bundledTool("unrar")
        ])
    }

    static func findUnar() -> String? {
        findExecutable([
            "/opt/homebrew/bin/unar",
            "/usr/local/bin/unar",
            "/Applications/The Unarchiver.app/Contents/MacOS/unar",
            bundledTool("unar")
        ])
    }

    private static func findExecutable(_ candidates: [String?]) -> String? {
        for path in candidates.compactMap({ $0 }) {
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return nil
    }

    private static func bundledTool(_ name: String) -> String? {
        if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "bin"),
           FileManager.default.isExecutableFile(atPath: url.path) {
            return url.path
        }
        let fallback = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources/bin/\(name)")
            .path
        return FileManager.default.isExecutableFile(atPath: fallback) ? fallback : nil
    }

    private static func run7z(_ args: [String]) throws {
        guard let bin = find7z() else {
            throw ArchiveError.toolFailed("未找到 7z。请执行：brew install p7zip")
        }
        try run(bin, args)
    }

    @discardableResult
    private static func run(_ launchPath: String, _ args: [String], cwd: String? = nil) throws -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        if let cwd { p.currentDirectoryURL = URL(fileURLWithPath: cwd) }
        let err = Pipe()
        p.standardOutput = Pipe()
        p.standardError = err
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus != 0 {
            let data = err.fileHandleForReading.readDataToEndOfFile()
            let msg = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw ArchiveError.toolFailed(msg?.isEmpty == false ? msg! : "命令失败 (\(launchPath))")
        }
        return p.terminationStatus
    }

    private static func runCapture(_ launchPath: String, _ args: [String]) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        let out = Pipe()
        let err = Pipe()
        p.standardOutput = out
        p.standardError = err
        try p.run()
        p.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        if p.terminationStatus != 0 {
            let e = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ArchiveError.toolFailed(e.isEmpty ? "读取归档失败" : e)
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

