import AppKit
import ClassicLaunchCore
import Foundation

enum AppLauncher {
    @MainActor
    static func launch(_ app: InstalledApp) {
        let appURL = URL(fileURLWithPath: app.path, isDirectory: true)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.promptsUserIfNeeded = true

        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            if let error {
                NSLog("Failed to launch app: %@", error.localizedDescription)
            }
        }
    }
}
