import XCTest
@testable import ClassicLaunchCore

final class LauncherStoreTests: XCTestCase {
    @MainActor
    func testBootstrapReconcilesAndAppendsUnplacedApps() {
        let apps = [
            InstalledApp(id: "a", name: "Alpha", bundleIdentifier: nil, path: "/Applications/Alpha.app", isSystemApp: false),
            InstalledApp(id: "b", name: "Bravo", bundleIdentifier: nil, path: "/Applications/Bravo.app", isSystemApp: false),
            InstalledApp(id: "c", name: "Charlie", bundleIdentifier: nil, path: "/Applications/Charlie.app", isSystemApp: false)
        ]

        let persisted = LauncherState(
            orderedEntries: [.app("b")]
        )

        let store = LauncherStore(
            indexer: MockIndexer(apps: apps),
            persistence: InMemoryPersistence(state: persisted),
            pageSize: 10
        )

        store.bootstrap()

        XCTAssertEqual(store.topLevelEntries.count, 3)
        XCTAssertEqual(store.topLevelEntries.map(\.title), ["Bravo", "Alpha", "Charlie"])
    }

    @MainActor
    func testCreateFolderFromSelection() {
        let apps = [
            InstalledApp(id: "a", name: "Alpha", bundleIdentifier: nil, path: "/Applications/Alpha.app", isSystemApp: false),
            InstalledApp(id: "b", name: "Bravo", bundleIdentifier: nil, path: "/Applications/Bravo.app", isSystemApp: false),
            InstalledApp(id: "c", name: "Charlie", bundleIdentifier: nil, path: "/Applications/Charlie.app", isSystemApp: false)
        ]

        let persisted = LauncherState(
            orderedEntries: [.app("a"), .app("b"), .app("c")]
        )

        let persistence = InMemoryPersistence(state: persisted)
        let store = LauncherStore(indexer: MockIndexer(apps: apps), persistence: persistence)
        store.bootstrap()

        store.createFolder(name: "개발", appIDs: ["a", "b"])

        XCTAssertEqual(store.topLevelEntries.count, 2)

        guard case .folder(let folder) = store.topLevelEntries[0] else {
            return XCTFail("Expected folder entry")
        }

        XCTAssertEqual(folder.name, "개발")
        XCTAssertEqual(folder.apps.map(\.id), ["a", "b"])

        let saved = persistence.state
        XCTAssertEqual(saved?.folders.count, 1)
    }

    @MainActor
    func testRemoveAppFromFolderCollapsesFolderWhenNeeded() {
        let apps = [
            InstalledApp(id: "a", name: "Alpha", bundleIdentifier: nil, path: "/Applications/Alpha.app", isSystemApp: false),
            InstalledApp(id: "b", name: "Bravo", bundleIdentifier: nil, path: "/Applications/Bravo.app", isSystemApp: false)
        ]

        let folder = LauncherFolder(id: "folder-1", name: "새 폴더", appIDs: ["a", "b"])
        let persisted = LauncherState(
            orderedEntries: [.folder(folder.id)],
            folders: [folder.id: folder]
        )

        let store = LauncherStore(
            indexer: MockIndexer(apps: apps),
            persistence: InMemoryPersistence(state: persisted)
        )

        store.bootstrap()
        store.removeAppFromFolder(appID: "a", folderID: folder.id)

        XCTAssertEqual(store.topLevelEntries.count, 2)
        XCTAssertEqual(store.topLevelEntries.map(\.title), ["Bravo", "Alpha"])
    }

    @MainActor
    func testHandleDropAppIntoFolder() {
        let apps = [
            InstalledApp(id: "a", name: "Alpha", bundleIdentifier: nil, path: "/Applications/Alpha.app", isSystemApp: false),
            InstalledApp(id: "b", name: "Bravo", bundleIdentifier: nil, path: "/Applications/Bravo.app", isSystemApp: false),
            InstalledApp(id: "c", name: "Charlie", bundleIdentifier: nil, path: "/Applications/Charlie.app", isSystemApp: false)
        ]

        let folder = LauncherFolder(id: "f1", name: "폴더", appIDs: ["a", "b"])
        let persisted = LauncherState(
            orderedEntries: [.app("c"), .folder(folder.id)],
            folders: [folder.id: folder]
        )

        let store = LauncherStore(
            indexer: MockIndexer(apps: apps),
            persistence: InMemoryPersistence(state: persisted)
        )

        store.bootstrap()

        store.handleDrop(draggedID: "app:c", onto: "folder:f1")

        XCTAssertEqual(store.topLevelEntries.count, 1)
        guard case .folder(let folderDisplay) = store.topLevelEntries[0] else {
            return XCTFail("Expected folder")
        }

        XCTAssertEqual(folderDisplay.apps.map(\.id), ["a", "b", "c"])
    }
}

private final class MockIndexer: AppIndexing {
    let apps: [InstalledApp]

    init(apps: [InstalledApp]) {
        self.apps = apps
    }

    func scanInstalledApps() throws -> [InstalledApp] {
        apps
    }
}

private final class InMemoryPersistence: LauncherStatePersisting {
    var state: LauncherState?

    init(state: LauncherState?) {
        self.state = state
    }

    func loadState() throws -> LauncherState? {
        state
    }

    func saveState(_ state: LauncherState) throws {
        self.state = state
    }
}
