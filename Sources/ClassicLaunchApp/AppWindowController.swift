import AppKit
import Foundation

enum AppWindowController {
    private static let mainWindowID = NSUserInterfaceItemIdentifier("ClassicLaunchMainWindow")

    @MainActor
    static func bindMainWindowIfNeeded() {
        guard let window = NSApp.windows.first else { return }
        if window.identifier == nil {
            window.identifier = mainWindowID
        }
    }

    @MainActor
    static func toggleMainWindow() {
        guard let window = primaryWindow else { return }

        if window.isVisible && NSApp.isActive {
            window.orderOut(nil)
            NSApp.hide(nil)
        } else {
            showMainWindow()
        }
    }

    @MainActor
    static func showMainWindow() {
        guard let window = primaryWindow else { return }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @MainActor
    static func hideMainWindow() {
        primaryWindow?.orderOut(nil)
    }

    @MainActor
    private static var primaryWindow: NSWindow? {
        NSApp.windows.first(where: { $0.identifier == mainWindowID }) ?? NSApp.windows.first
    }
}
