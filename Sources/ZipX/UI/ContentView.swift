import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = ZipXViewModel()
    @ObservedObject private var updater = UpdateChecker.shared
    @State private var showAbout = false

    var body: some View {
        ZStack {
            ZipXBrand.canvas.ignoresSafeArea()
            // soft wash
            Circle()
                .fill(ZipXBrand.accentColor.opacity(0.08))
                .frame(width: 420, height: 420)
                .blur(radius: 60)
                .offset(x: 280, y: -220)
            Circle()
                .fill(ZipXBrand.extractTone.opacity(0.07))
                .frame(width: 360, height: 360)
                .blur(radius: 50)
                .offset(x: -300, y: 260)

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        dropZone
                        if !model.items.isEmpty {
                            fileSection
                            actionChooser
                            if model.pendingAction != nil {
                                optionsPanel
                                confirmBar
                            }
                            if !model.previewEntries.isEmpty {
                                previewList
                            }
                        }
                        if !model.status.isEmpty {
                            Text(model.status)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(ZipXBrand.inkMuted)
                        }
                    }
                    .padding(28)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 560)
        .preferredColorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: .zipxOpenFiles)) { note in
            if let urls = note.object as? [URL] { model.add(urls) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zipxPickFiles)) { _ in
            model.pickFiles()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zipxShowAbout)) { _ in
            showAbout = true
        }
        .sheet(isPresented: $showAbout) {
            AboutView(isPresented: $showAbout)
        }
    }

    // MARK: - Top

    private var topBar: some View {
        HStack(spacing: 12) {
            ZipXBrandMark(size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(ZipXBrand.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(ZipXBrand.ink)
                Text("先选文件，再选压缩或解压")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ZipXBrand.inkMuted)
            }
            Spacer()
            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
            toolbarChip("检查更新") { updater.check(manual: true) }
            toolbarChip("关于") { showAbout = true }
        }
        .padding(.horizontal, 28)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private func toolbarChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ZipXBrand.inkMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(ZipXBrand.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(ZipXBrand.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Drop

    private var dropZone: some View {
        let active = model.isDropTargeted
        return ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ZipXBrand.surface)
                .shadow(color: Color.black.opacity(0.04), radius: 16, y: 6)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    active ? ZipXBrand.accentColor : ZipXBrand.line,
                    style: StrokeStyle(lineWidth: active ? 2 : 1.2, dash: active ? [] : [7, 6])
                )
            VStack(spacing: 10) {
                Image(systemName: "plus.rectangle.on.folder.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(ZipXBrand.accentColor)
                Text(model.items.isEmpty ? "拖入文件或文件夹" : "继续添加文件")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(ZipXBrand.ink)
                Text("点击此处选择 · ZIP / 7Z / RAR / 文件夹均可")
                    .font(.system(size: 12))
                    .foregroundStyle(ZipXBrand.inkMuted)
                HStack(spacing: 8) {
                    Button("选择文件…") { model.pickFiles() }
                        .buttonStyle(ZipXPrimaryButtonStyle())
                    if !model.items.isEmpty {
                        Button("清空") { model.clear() }
                            .buttonStyle(ZipXGhostButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(28)
        }
        .frame(minHeight: model.items.isEmpty ? 200 : 150)
        .contentShape(Rectangle())
        .onTapGesture { model.pickFiles() }
        .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted) { model.handleDrop($0) }
    }

    // MARK: - Files

    private var fileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("已选 \(model.items.count) 项")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ZipXBrand.ink)
                if model.archiveCount > 0 {
                    Text("· 其中 \(model.archiveCount) 个压缩包")
                        .font(.system(size: 12))
                        .foregroundStyle(ZipXBrand.inkMuted)
                }
                Spacer()
            }
            VStack(spacing: 0) {
                ForEach(Array(model.items.enumerated()), id: \.element) { index, url in
                    HStack(spacing: 10) {
                        Image(systemName: icon(for: url))
                            .foregroundStyle(ArchiveService.isArchive(url) ? ZipXBrand.extractTone : ZipXBrand.compressTone)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ZipXBrand.ink)
                                .lineLimit(1)
                            Text(url.deletingLastPathComponent().path)
                                .font(.system(size: 10))
                                .foregroundStyle(ZipXBrand.inkMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(model.sizeLabel(for: url))
                            .font(.system(size: 11, weight: .medium).monospacedDigit())
                            .foregroundStyle(ZipXBrand.inkMuted)
                        Button {
                            model.remove(url)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(ZipXBrand.inkMuted.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    if index < model.items.count - 1 {
                        Divider().background(ZipXBrand.line)
                    }
                }
            }
            .background(ZipXBrand.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ZipXBrand.line, lineWidth: 1)
            )
        }
    }

    private func icon(for url: URL) -> String {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if isDir.boolValue { return "folder.fill" }
        return ArchiveService.isArchive(url) ? "doc.zipper" : "doc.fill"
    }

    // MARK: - Action chooser (选完文件后再选操作)

    private var actionChooser: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("接下来要做什么？")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(ZipXBrand.ink)

            HStack(spacing: 12) {
                actionCard(
                    title: "压缩",
                    subtitle: "打成 ZIP / 7Z / RAR",
                    systemImage: "arrow.down.to.line.compact",
                    color: ZipXBrand.compressTone,
                    selected: model.pendingAction == .compress,
                    enabled: true
                ) {
                    model.pendingAction = .compress
                }

                actionCard(
                    title: "解压",
                    subtitle: model.archiveCount > 0 ? "解压 \(model.archiveCount) 个包" : "需要压缩包",
                    systemImage: "arrow.up.right.and.arrow.down.left",
                    color: ZipXBrand.extractTone,
                    selected: model.pendingAction == .extract,
                    enabled: model.archiveCount > 0
                ) {
                    model.pendingAction = .extract
                }

                actionCard(
                    title: "预览",
                    subtitle: "查看包内文件",
                    systemImage: "eye",
                    color: ZipXBrand.previewTone,
                    selected: model.pendingAction == .preview,
                    enabled: model.archiveCount > 0
                ) {
                    model.pendingAction = .preview
                    Task { await model.runPreviewOnly() }
                }
            }
        }
    }

    private func actionCard(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color,
        selected: Bool,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(enabled ? color : ZipXBrand.inkMuted.opacity(0.4))
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(enabled ? ZipXBrand.ink : ZipXBrand.inkMuted.opacity(0.5))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(ZipXBrand.inkMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ZipXBrand.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? color : ZipXBrand.line, lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? color.opacity(0.18) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }

    // MARK: - Options + confirm

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            if model.pendingAction == .compress {
                Text("压缩选项")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ZipXBrand.ink)
                HStack(spacing: 16) {
                    Picker("格式", selection: $model.options.format) {
                        ForEach(CompressFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 240)

                    Toggle("固实", isOn: $model.options.solid)
                    Toggle("压到原目录", isOn: $model.saveBesideSource)

                    HStack(spacing: 6) {
                        Text("分卷")
                        TextField("0", value: $model.options.splitMB, format: .number)
                            .frame(width: 52)
                            .textFieldStyle(.roundedBorder)
                        Text("MB")
                            .foregroundStyle(ZipXBrand.inkMuted)
                    }
                    .font(.system(size: 12))
                }
                if model.options.format == .rar && !ArchiveService.canCreateRAR() {
                    Text("创建 RAR 需安装：brew install --cask rar")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ZipXBrand.compressTone)
                }
                if model.options.format == .sevenZ && ArchiveService.find7z() == nil {
                    Text("创建 7Z 需安装：brew install p7zip")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ZipXBrand.compressTone)
                }
                SecureField("加密密码（可选）", text: $model.options.password)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
            }

            if model.pendingAction == .extract {
                Text("解压选项")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ZipXBrand.ink)
                Toggle("解压到压缩包所在目录", isOn: $model.extractBesideArchive)
                if model.items.contains(where: { $0.pathExtension.lowercased() == "rar" || $0.pathExtension.lowercased() == "cbr" })
                    && !ArchiveService.canExtractRAR() {
                    Text("解压 RAR 需安装：brew install p7zip 或 unar")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ZipXBrand.extractTone)
                }
                SecureField("密码（如有）", text: $model.options.password)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
            }

            if model.pendingAction == .preview {
                SecureField("预览密码（如有）", text: $model.options.password)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ZipXBrand.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ZipXBrand.line, lineWidth: 1)
        )
    }

    private var confirmBar: some View {
        HStack {
            Button("取消选择") {
                model.pendingAction = nil
                model.previewEntries = []
            }
            .buttonStyle(ZipXGhostButtonStyle())

            Spacer()

            if model.isBusy {
                ProgressView().controlSize(.small)
            }

            Button(model.confirmTitle) {
                Task { await model.runPendingAction() }
            }
            .buttonStyle(ZipXPrimaryButtonStyle(color: model.confirmColor))
            .disabled(model.isBusy)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var previewList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("归档内容 · \(model.previewEntries.count) 项")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ZipXBrand.ink)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(model.previewEntries) { entry in
                        HStack {
                            Image(systemName: entry.isDirectory ? "folder" : "doc")
                                .foregroundStyle(ZipXBrand.previewTone)
                            Text(entry.path)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            if let size = entry.size {
                                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                    .font(.caption)
                                    .foregroundStyle(ZipXBrand.inkMuted)
                            }
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 220)
            .background(ZipXBrand.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ZipXBrand.line, lineWidth: 1)
            )
        }
    }
}

// MARK: - Buttons

struct ZipXPrimaryButtonStyle: ButtonStyle {
    var color: Color = ZipXBrand.accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(color.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(Capsule())
    }
}

struct ZipXGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(ZipXBrand.inkMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(ZipXBrand.surface.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(ZipXBrand.line, lineWidth: 1))
    }
}

// MARK: - Model

@MainActor
final class ZipXViewModel: ObservableObject {
    enum PendingAction {
        case compress, extract, preview
    }

    @Published var items: [URL] = []
    @Published var options = CompressOptions()
    @Published var status = ""
    @Published var isBusy = false
    @Published var isDropTargeted = false
    @Published var previewEntries: [ArchiveEntry] = []
    @Published var pendingAction: PendingAction?
    @Published var saveBesideSource = true
    @Published var extractBesideArchive = true

    var archiveCount: Int { items.filter(ArchiveService.isArchive).count }

    var confirmTitle: String {
        switch pendingAction {
        case .compress: return "开始压缩"
        case .extract: return "开始解压"
        case .preview: return "刷新预览"
        case .none: return "开始"
        }
    }

    var confirmColor: Color {
        switch pendingAction {
        case .compress: return ZipXBrand.compressTone
        case .extract: return ZipXBrand.extractTone
        case .preview: return ZipXBrand.previewTone
        case .none: return ZipXBrand.accentColor
        }
    }

    func clear() {
        items = []
        previewEntries = []
        pendingAction = nil
        status = ""
    }

    func remove(_ url: URL) {
        items.removeAll { $0 == url }
        if items.isEmpty {
            pendingAction = nil
            previewEntries = []
        }
    }

    func add(_ urls: [URL]) {
        for url in urls where !items.contains(url) {
            _ = url.startAccessingSecurityScopedResource()
            items.append(url)
        }
        // 选完文件后不自动开干，等用户选压缩/解压；有压缩包时默认高亮解压可选
        if pendingAction == nil, archiveCount > 0, items.allSatisfy(ArchiveService.isArchive) {
            // 仅提示，不强制
        }
        status = "已添加，请选择：压缩 / 解压 / 预览"
    }

    func sizeLabel(for url: URL) -> String {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return "—" }
        if isDir.boolValue { return "文件夹" }
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    func pickFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "添加"
        panel.message = "选择要压缩或解压的文件"
        if panel.runModal() == .OK {
            add(panel.urls)
        }
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        var urls: [URL] = []
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                } else if let url = item as? URL {
                    urls.append(url)
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.add(urls)
        }
        return !providers.isEmpty
    }

    func runPreviewOnly() async {
        await runPendingAction()
    }

    func runPendingAction() async {
        guard let action = pendingAction, !items.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            switch action {
            case .compress: try await compress()
            case .extract: try await extract()
            case .preview: try await preview()
            }
        } catch {
            status = error.localizedDescription
            presentError(error.localizedDescription)
        }
    }

    private func compress() async throws {
        var dest: URL
        if saveBesideSource, let first = items.first {
            dest = first.deletingLastPathComponent()
                .appendingPathComponent(suggestedArchiveName())
            if FileManager.default.fileExists(atPath: dest.path) {
                dest = uniqueURL(dest)
            }
        } else {
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = suggestedArchiveName()
            panel.allowedContentTypes = [
                UTType.zip,
                UTType(filenameExtension: "7z"),
                UTType(filenameExtension: "rar")
            ].compactMap { $0 }
            guard panel.runModal() == .OK, let url = panel.url else { return }
            dest = url
        }

        var opts = options
        if opts.solid && opts.format == .zip && ArchiveService.find7z() != nil {
            opts.format = .sevenZ
            dest = dest.deletingPathExtension().appendingPathExtension("7z")
        } else {
            dest = dest.deletingPathExtension().appendingPathExtension(opts.format.fileExtension)
        }

        status = "压缩中…"
        try await ArchiveService.compress(sources: items, destination: dest, options: opts) { [weak self] msg in
            Task { @MainActor in self?.status = msg }
        }
        status = "已保存：\(dest.path)"
        NSWorkspace.shared.activateFileViewerSelecting([dest])
    }

    private func extract() async throws {
        let archives = items.filter(ArchiveService.isArchive)
        guard !archives.isEmpty else { throw ArchiveError.toolFailed("请先选择压缩包再解压") }

        var baseDir: URL?
        if !extractBesideArchive {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.prompt = "解压到此"
            panel.message = "选择解压目标文件夹"
            guard panel.runModal() == .OK, let dir = panel.url else { return }
            baseDir = dir
        }

        for archive in archives {
            let parent = baseDir ?? archive.deletingLastPathComponent()
            var out = parent.appendingPathComponent(archive.deletingPathExtension().lastPathComponent)
            if FileManager.default.fileExists(atPath: out.path) {
                out = uniqueURL(out, isDirectory: true)
            }
            status = "解压 \(archive.lastPathComponent)…"
            try await ArchiveService.extract(
                archive: archive,
                destination: out,
                password: options.password
            ) { [weak self] msg in
                Task { @MainActor in self?.status = msg }
            }
        }
        status = "解压完成 · 共 \(archives.count) 个"
        if let first = archives.first {
            let folder = (baseDir ?? first.deletingLastPathComponent())
            NSWorkspace.shared.open(folder)
        }
    }

    private func preview() async throws {
        guard let archive = items.first(where: ArchiveService.isArchive) else {
            throw ArchiveError.toolFailed("请选择压缩包以预览")
        }
        status = "读取中…"
        previewEntries = try await ArchiveService.listContents(of: archive, password: options.password)
        status = "共 \(previewEntries.count) 项 · \(archive.lastPathComponent)"
    }

    private func suggestedArchiveName() -> String {
        if items.count == 1 {
            return items[0].deletingPathExtension().lastPathComponent + ".\(options.format.fileExtension)"
        }
        return "归档.\(options.format.fileExtension)"
    }

    private func uniqueURL(_ url: URL, isDirectory: Bool = false) -> URL {
        let parent = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var i = 2
        while true {
            let name = isDirectory || ext.isEmpty ? "\(base) \(i)" : "\(base) \(i).\(ext)"
            let candidate = parent.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            i += 1
        }
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "操作失败"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
