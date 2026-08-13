import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var openURLs: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        DistributedNotificationCenter.default().addObserver(
            forName: zipxReopenNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showMainWindow()
        }

        installMenu()
        showMainWindow()

        if !openURLs.isEmpty {
            NotificationCenter.default.post(name: .zipxOpenFiles, object: openURLs)
            openURLs.removeAll()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            Task { @MainActor in
                let auto = UserDefaults.standard.object(forKey: "zipx.autoCheckUpdate") as? Bool ?? true
                if auto {
                    UpdateChecker.shared.check(manual: false)
                }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if window == nil {
            openURLs.append(contentsOf: urls)
        } else {
            NotificationCenter.default.post(name: .zipxOpenFiles, object: urls)
            showMainWindow()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    private func showMainWindow() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let root = ContentView()
        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ZipXBrand.name
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(calibratedRed: 0.945, green: 0.953, blue: 0.965, alpha: 1)
        window.minSize = NSSize(width: 760, height: 560)
        window.contentViewController = hosting
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    private func installMenu() {
        let main = NSMenu()

        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu(title: ZipXBrand.name)
        appMenu.submenu?.addItem(withTitle: "关于 \(ZipXBrand.name)", action: #selector(showAbout), keyEquivalent: "")
        appMenu.submenu?.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.submenu?.addItem(.separator())
        appMenu.submenu?.addItem(withTitle: "检查更新…", action: #selector(checkUpdates), keyEquivalent: "")
        appMenu.submenu?.addItem(.separator())
        appMenu.submenu?.addItem(withTitle: "隐藏 \(ZipXBrand.name)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.submenu?.addItem(hideOthers)
        appMenu.submenu?.addItem(.separator())
        appMenu.submenu?.addItem(withTitle: "退出 \(ZipXBrand.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        main.addItem(appMenu)

        let fileMenu = NSMenuItem()
        fileMenu.submenu = NSMenu(title: "文件")
        fileMenu.submenu?.addItem(withTitle: "添加文件…", action: #selector(addFiles), keyEquivalent: "o")
        fileMenu.submenu?.addItem(withTitle: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        main.addItem(fileMenu)

        let helpMenu = NSMenuItem()
        helpMenu.submenu = NSMenu(title: "帮助")
        let site = NSMenuItem(title: "官网 \(ZipXBrand.websiteHost)", action: #selector(openWebsite), keyEquivalent: "")
        helpMenu.submenu?.addItem(site)
        let gh = NSMenuItem(title: "GitHub \(ZipXBrand.githubHost)", action: #selector(openGitHub), keyEquivalent: "")
        helpMenu.submenu?.addItem(gh)
        main.addItem(helpMenu)

        NSApp.mainMenu = main
    }

    @objc private func showAbout() {
        NotificationCenter.default.post(name: .zipxShowAbout, object: nil)
        showMainWindow()
    }

    @objc private func showSettings() {
        NotificationCenter.default.post(name: .zipxShowSettings, object: nil)
        showMainWindow()
    }

    @objc private func checkUpdates() {
        Task { @MainActor in
            UpdateChecker.shared.check(manual: true)
        }
    }

    @objc private func addFiles() {
        NotificationCenter.default.post(name: .zipxPickFiles, object: nil)
        showMainWindow()
    }

    @objc private func openWebsite() {
        NSWorkspace.shared.open(ZipXBrand.websiteURL)
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(ZipXBrand.githubURL)
    }
}

extension Notification.Name {
    static let zipxOpenFiles = Notification.Name("zipx.openFiles")
    static let zipxPickFiles = Notification.Name("zipx.pickFiles")
    static let zipxShowAbout = Notification.Name("zipx.showAbout")
    static let zipxShowSettings = Notification.Name("zipx.showSettings")
}
