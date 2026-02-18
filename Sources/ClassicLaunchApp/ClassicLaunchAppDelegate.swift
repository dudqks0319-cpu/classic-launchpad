import AppKit
import Foundation

final class ClassicLaunchAppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyManager = GlobalHotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.register {
            Task { @MainActor in
                AppWindowController.toggleMainWindow()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }
}
