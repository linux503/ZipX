import AppKit

let zipxReopenNotification = Notification.Name("app.zipx.mac.reopen")

func enforceSingleInstance() {
    let bundleID = Bundle.main.bundleIdentifier ?? "app.zipx.mac"
    let myPID = ProcessInfo.processInfo.processIdentifier
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .filter { $0.processIdentifier != myPID && !$0.isTerminated }

    guard let existing = others.first else { return }

    DistributedNotificationCenter.default().postNotificationName(
        zipxReopenNotification,
        object: bundleID,
        userInfo: nil,
        deliverImmediately: true
    )
    _ = existing.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    usleep(120_000)
    exit(0)
}

enforceSingleInstance()

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
