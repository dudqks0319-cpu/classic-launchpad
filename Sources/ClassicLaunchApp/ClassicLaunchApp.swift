import ClassicLaunchCore
import SwiftUI

@main
struct ClassicLaunchApp: App {
    @NSApplicationDelegateAdaptor(ClassicLaunchAppDelegate.self) private var appDelegate

    @StateObject private var store = LauncherStore(
        indexer: DefaultAppIndexer(),
        persistence: FileLauncherStatePersistence.default(),
        pageSize: 35
    )

    var body: some Scene {
        WindowGroup("ClassicLaunch") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 700)
                .onAppear {
                    AppWindowController.bindMainWindowIfNeeded()
                    store.bootstrap()
                }
        }
        .windowResizability(.contentSize)

        Commands {
            CommandMenu("ClassicLaunch") {
                Button("런처 토글") {
                    Task { @MainActor in
                        AppWindowController.toggleMainWindow()
                    }
                }
                .keyboardShortcut("l", modifiers: [.command, .option])

                Button("앱 목록 새로고침") {
                    store.reloadApps()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("검색창으로 이동") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let focusSearch = Notification.Name("ClassicLaunch.FocusSearch")
}
