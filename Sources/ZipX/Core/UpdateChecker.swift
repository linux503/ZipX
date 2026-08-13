import AppKit
import Foundation

struct UpdateInfo: Equatable {
    let version: String
    let notes: String
    let downloadURL: URL?
    let releaseURL: URL?
}

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published var isChecking = false
    @Published var lastMessage: String?
    @Published var available: UpdateInfo?

    func check(manual: Bool) {
        guard !isChecking else { return }
        isChecking = true
        lastMessage = manual ? "正在检查更新…" : nil

        Task {
            defer { isChecking = false }
            do {
                if let info = try await fetchUpdate() {
                    if isNewer(info.version, than: ZipXBrand.version) {
                        available = info
                        lastMessage = "发现新版本 \(info.version)"
                        if manual || shouldPromptAutomatically() {
                            presentAlert(info)
                        }
                    } else {
                        available = nil
                        lastMessage = "已是最新版本 \(ZipXBrand.version)"
                        if manual {
                            presentUpToDate()
                        }
                    }
                } else if manual {
                    lastMessage = "暂未获取到版本信息"
                    presentUpToDate(title: "检查完成", body: "暂时无法从官网或 GitHub 获取版本信息。\n可稍后重试，或前往官网查看。")
                }
            } catch {
                lastMessage = error.localizedDescription
                if manual {
                    presentUpToDate(title: "检查失败", body: error.localizedDescription)
                }
            }
        }
    }

    private func shouldPromptAutomatically() -> Bool {
        let key = "zipx.lastUpdatePrompt"
        let last = UserDefaults.standard.object(forKey: key) as? Date ?? .distantPast
        if Date().timeIntervalSince(last) < 60 * 60 * 12 { return false }
        UserDefaults.standard.set(Date(), forKey: key)
        return true
    }

    private func fetchUpdate() async throws -> UpdateInfo? {
        if let info = try? await fetchFromWebsite() { return info }
        return try await fetchFromGitHub()
    }

    private func fetchFromWebsite() async throws -> UpdateInfo? {
        var req = URLRequest(url: ZipXBrand.updateFeedURL)
        req.timeoutInterval = 12
        req.setValue("ZipX/\(ZipXBrand.version)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = json["version"] as? String else { return nil }
        let notes = (json["notes"] as? String) ?? ""
        let dmg = (json["dmg"] as? String).flatMap(URL.init(string:))
        let page = (json["url"] as? String).flatMap(URL.init(string:)) ?? ZipXBrand.websiteURL
        return UpdateInfo(version: version, notes: notes, downloadURL: dmg ?? page, releaseURL: page)
    }

    private func fetchFromGitHub() async throws -> UpdateInfo? {
        var req = URLRequest(url: ZipXBrand.githubLatestAPI)
        req.timeoutInterval = 12
        req.setValue("ZipX/\(ZipXBrand.version)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let tag = (json["tag_name"] as? String)?.trimmingCharacters(in: CharacterSet(charactersIn: "vV")) ?? ""
        guard !tag.isEmpty else { return nil }
        let notes = (json["body"] as? String) ?? ""
        let html = (json["html_url"] as? String).flatMap(URL.init(string:))
        var dmg: URL?
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let name = asset["name"] as? String,
                   name.lowercased().hasSuffix(".dmg"),
                   let url = (asset["browser_download_url"] as? String).flatMap(URL.init(string:)) {
                    dmg = url
                    break
                }
            }
        }
        return UpdateInfo(version: tag, notes: notes, downloadURL: dmg ?? html, releaseURL: html)
    }

    private func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        let count = max(r.count, l.count)
        for i in 0..<count {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }

    private func presentAlert(_ info: UpdateInfo) {
        let alert = NSAlert()
        alert.messageText = "发现新版本 \(info.version)"
        alert.informativeText = info.notes.isEmpty
            ? "当前版本 \(ZipXBrand.version)。是否前往下载更新？"
            : String(info.notes.prefix(500))
        alert.alertStyle = .informational
        alert.addButton(withTitle: "立即更新")
        alert.addButton(withTitle: "稍后再说")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = info.downloadURL ?? info.releaseURL {
                NSWorkspace.shared.open(url)
            } else {
                NSWorkspace.shared.open(ZipXBrand.websiteURL)
            }
        }
    }

    private func presentUpToDate(title: String = "已是最新", body: String? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body ?? "当前版本 \(ZipXBrand.version)，无需更新。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")
        alert.addButton(withTitle: "打开官网")
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(ZipXBrand.websiteURL)
        }
    }
}
