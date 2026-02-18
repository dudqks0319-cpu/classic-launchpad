import Combine
import Foundation

@MainActor
public final class LauncherStore: ObservableObject {
    @Published public private(set) var installedApps: [InstalledApp] = [] {
        didSet {
            installedAppsByIDCache = Dictionary(uniqueKeysWithValues: installedApps.map { ($0.id, $0) })
        }
    }
    @Published public private(set) var state: LauncherState = .empty
    @Published public var searchQuery: String = ""
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var errorMessage: String?

    public let pageSize: Int

    private let indexer: AppIndexing
    private let persistence: LauncherStatePersisting

    private var installedAppsByIDCache: [String: InstalledApp] = [:]
    private var didBootstrap = false

    public init(
        indexer: AppIndexing,
        persistence: LauncherStatePersisting,
        pageSize: Int = 35
    ) {
        self.indexer = indexer
        self.persistence = persistence
        self.pageSize = pageSize
    }

    public func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true

        do {
            if let loaded = try persistence.loadState() {
                state = loaded
            }
        } catch {
            errorMessage = "상태 파일을 불러오지 못했어요: \(error.localizedDescription)"
        }

        reloadApps()
    }

    public func reloadApps() {
        do {
            let scannedApps = try indexer.scanInstalledApps()
            installedApps = scannedApps
            reconcileStateWithInstalledApps()
            lastSyncDate = Date()
            errorMessage = nil
        } catch {
            errorMessage = "앱 목록을 스캔하지 못했어요: \(error.localizedDescription)"
        }
    }

    public func setSearchQuery(_ value: String) {
        searchQuery = value
    }

    public var installedAppsByID: [String: InstalledApp] {
        installedAppsByIDCache
    }

    public var topLevelEntries: [DisplayEntry] {
        let appMap = installedAppsByID

        return state.orderedEntries.compactMap { entry in
            switch entry {
            case .app(let appID):
                guard let app = appMap[appID] else { return nil }
                return .app(app)
            case .folder(let folderID):
                guard let folder = state.folders[folderID] else { return nil }
                let apps = folder.appIDs.compactMap { appMap[$0] }
                guard apps.count >= 2 else { return nil }
                return .folder(DisplayFolder(id: folder.id, name: folder.name, apps: apps))
            }
        }
    }

    public var pagedEntries: [[DisplayEntry]] {
        chunked(topLevelEntries, by: max(pageSize, 1))
    }

    public var searchResults: [InstalledApp] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        return installedApps
            .filter { app in
                app.name.localizedCaseInsensitiveContains(query)
                    || app.path.localizedCaseInsensitiveContains(query)
                    || (app.bundleIdentifier?.localizedCaseInsensitiveContains(query) ?? false)
            }
            .sorted {
                let lhsPrefix = $0.name.localizedLowercase.hasPrefix(query.localizedLowercase)
                let rhsPrefix = $1.name.localizedLowercase.hasPrefix(query.localizedLowercase)

                if lhsPrefix != rhsPrefix {
                    return lhsPrefix
                }

                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    public var allFolders: [LauncherFolder] {
        state.folders.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    public func app(for appID: String) -> InstalledApp? {
        installedAppsByID[appID]
    }

    public func moveEntry(draggedID: String, before targetID: String) {
        guard draggedID != targetID,
              let draggedEntry = parseDisplayEntryID(draggedID),
              let targetEntry = parseDisplayEntryID(targetID),
              let from = state.orderedEntries.firstIndex(of: draggedEntry),
              let rawTo = state.orderedEntries.firstIndex(of: targetEntry)
        else {
            return
        }

        var entries = state.orderedEntries
        let moving = entries.remove(at: from)
        let to = rawTo > from ? rawTo - 1 : rawTo
        entries.insert(moving, at: max(0, min(to, entries.count)))
        state.orderedEntries = entries
        touchAndSave()
    }

    public func createFolder(name: String, appIDs: [String]) {
        let uniqueIDs = deduplicated(appIDs).filter { installedAppsByID[$0] != nil }
        guard uniqueIDs.count >= 2 else { return }

        let topLevelOrder: [String: Int] = Dictionary(uniqueKeysWithValues: state.orderedEntries.enumerated().compactMap { index, entry in
            if case .app(let appID) = entry {
                return (appID, index)
            }
            return nil
        })

        let originalOrder: [String: Int] = Dictionary(uniqueKeysWithValues: uniqueIDs.enumerated().map { ($1, $0) })

        let orderedIDs = uniqueIDs.sorted { lhs, rhs in
            let lhsTopLevelIndex = topLevelOrder[lhs] ?? Int.max
            let rhsTopLevelIndex = topLevelOrder[rhs] ?? Int.max

            if lhsTopLevelIndex == rhsTopLevelIndex {
                return (originalOrder[lhs] ?? 0) < (originalOrder[rhs] ?? 0)
            }

            return lhsTopLevelIndex < rhsTopLevelIndex
        }

        let insertionIndex = orderedIDs
            .compactMap { id in state.orderedEntries.firstIndex(of: .app(id)) }
            .min() ?? state.orderedEntries.count

        // 기존 배치에서 제거
        removeAppsFromCurrentPlacement(orderedIDs)

        let folder = LauncherFolder(name: name, appIDs: orderedIDs)
        state.folders[folder.id] = folder

        state.orderedEntries.insert(.folder(folder.id), at: min(insertionIndex, state.orderedEntries.count))
        touchAndSave()
    }

    public func createFolderFromTopLevel(firstAppID: String, secondAppID: String, name: String = "새 폴더") {
        guard firstAppID != secondAppID else { return }

        let first = LauncherEntry.app(firstAppID)
        let second = LauncherEntry.app(secondAppID)

        guard let firstIndex = state.orderedEntries.firstIndex(of: first),
              let secondIndex = state.orderedEntries.firstIndex(of: second)
        else {
            return
        }

        let insertionIndex = min(firstIndex, secondIndex)

        state.orderedEntries.removeAll { entry in
            switch entry {
            case .app(let id):
                return id == firstAppID || id == secondAppID
            default:
                return false
            }
        }

        let folder = LauncherFolder(name: name, appIDs: [firstAppID, secondAppID])
        state.folders[folder.id] = folder
        state.orderedEntries.insert(.folder(folder.id), at: insertionIndex)

        touchAndSave()
    }

    public func renameFolder(folderID: String, name: String) {
        guard var folder = state.folders[folderID] else { return }
        folder.name = name
        state.folders[folderID] = folder
        touchAndSave()
    }

    public func addAppToFolder(appID: String, folderID: String) {
        guard var folder = state.folders[folderID] else { return }
        guard installedAppsByID[appID] != nil else { return }

        removeAppsFromCurrentPlacement([appID])
        if !folder.appIDs.contains(appID) {
            folder.appIDs.append(appID)
        }

        state.folders[folderID] = folder

        if !state.orderedEntries.contains(.folder(folderID)) {
            state.orderedEntries.append(.folder(folderID))
        }

        touchAndSave()
    }

    public func removeAppFromFolder(appID: String, folderID: String) {
        guard var folder = state.folders[folderID],
              let folderIndex = state.orderedEntries.firstIndex(of: .folder(folderID))
        else {
            return
        }

        folder.appIDs.removeAll { $0 == appID }

        if folder.appIDs.count >= 2 {
            state.folders[folderID] = folder
            state.orderedEntries.insert(.app(appID), at: min(folderIndex + 1, state.orderedEntries.count))
        } else if folder.appIDs.count == 1 {
            let survivor = folder.appIDs[0]
            state.folders.removeValue(forKey: folderID)
            state.orderedEntries.removeAll { $0 == .folder(folderID) }
            state.orderedEntries.insert(.app(survivor), at: min(folderIndex, state.orderedEntries.count))
            state.orderedEntries.insert(.app(appID), at: min(folderIndex + 1, state.orderedEntries.count))
        } else {
            state.folders.removeValue(forKey: folderID)
            state.orderedEntries.removeAll { $0 == .folder(folderID) }
            state.orderedEntries.insert(.app(appID), at: min(folderIndex, state.orderedEntries.count))
        }

        touchAndSave()
    }

    public func dissolveFolder(folderID: String) {
        guard let folder = state.folders[folderID],
              let folderIndex = state.orderedEntries.firstIndex(of: .folder(folderID))
        else {
            return
        }

        state.folders.removeValue(forKey: folderID)
        state.orderedEntries.removeAll { $0 == .folder(folderID) }

        for (index, appID) in folder.appIDs.enumerated() {
            state.orderedEntries.insert(.app(appID), at: min(folderIndex + index, state.orderedEntries.count))
        }

        touchAndSave()
    }

    public func handleDrop(draggedID: String, onto targetID: String) {
        guard draggedID != targetID,
              let dragged = parseDisplayEntryID(draggedID),
              let target = parseDisplayEntryID(targetID)
        else {
            return
        }

        switch (dragged, target) {
        case (.app(let draggedApp), .folder(let folderID)):
            addAppToFolder(appID: draggedApp, folderID: folderID)
        case (.app(let draggedApp), .app(let targetApp)):
            createFolderFromTopLevel(firstAppID: draggedApp, secondAppID: targetApp)
        default:
            moveEntry(draggedID: draggedID, before: targetID)
        }
    }

    public func ensureAppOnTopLevel(_ appID: String) {
        guard installedAppsByID[appID] != nil else { return }

        removeAppsFromCurrentPlacement([appID])
        state.orderedEntries.append(.app(appID))
        touchAndSave()
    }

    private func reconcileStateWithInstalledApps() {
        let appMap = installedAppsByID
        let installedIDs = Set(appMap.keys)

        var sanitizedFolders: [String: LauncherFolder] = [:]
        var usedAppIDs = Set<String>()
        var sanitizedEntries: [LauncherEntry] = []

        for entry in state.orderedEntries {
            switch entry {
            case .app(let appID):
                guard installedIDs.contains(appID), !usedAppIDs.contains(appID) else { continue }
                sanitizedEntries.append(.app(appID))
                usedAppIDs.insert(appID)

            case .folder(let folderID):
                guard var folder = state.folders[folderID] else { continue }

                folder.appIDs = deduplicated(folder.appIDs).filter {
                    installedIDs.contains($0) && !usedAppIDs.contains($0)
                }

                if folder.appIDs.count >= 2 {
                    sanitizedFolders[folderID] = folder
                    sanitizedEntries.append(.folder(folderID))
                    usedAppIDs.formUnion(folder.appIDs)
                } else if folder.appIDs.count == 1 {
                    let appID = folder.appIDs[0]
                    sanitizedEntries.append(.app(appID))
                    usedAppIDs.insert(appID)
                }
            }
        }

        let unplaced = installedApps
            .filter { !usedAppIDs.contains($0.id) }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            .map { LauncherEntry.app($0.id) }

        sanitizedEntries.append(contentsOf: unplaced)

        state.orderedEntries = sanitizedEntries
        state.folders = sanitizedFolders
        touchAndSave()
    }

    private func removeAppsFromCurrentPlacement(_ appIDs: [String]) {
        let appSet = Set(appIDs)

        state.orderedEntries.removeAll {
            if case .app(let appID) = $0 {
                return appSet.contains(appID)
            }
            return false
        }

        for folderID in Array(state.folders.keys) {
            guard var folder = state.folders[folderID] else { continue }

            folder.appIDs.removeAll { appSet.contains($0) }

            if folder.appIDs.count >= 2 {
                state.folders[folderID] = folder
            } else {
                state.folders.removeValue(forKey: folderID)
                state.orderedEntries.removeAll { $0 == .folder(folderID) }

                if let survivor = folder.appIDs.first {
                    state.orderedEntries.append(.app(survivor))
                }
            }
        }
    }

    private func touchAndSave() {
        state.updatedAt = Date()
        do {
            try persistence.saveState(state)
        } catch {
            errorMessage = "상태 저장에 실패했어요: \(error.localizedDescription)"
        }
    }

    private func parseDisplayEntryID(_ displayID: String) -> LauncherEntry? {
        if displayID.hasPrefix("app:") {
            return .app(String(displayID.dropFirst(4)))
        }
        if displayID.hasPrefix("folder:") {
            return .folder(String(displayID.dropFirst(7)))
        }
        return nil
    }

    private func chunked<T>(_ array: [T], by size: Int) -> [[T]] {
        guard size > 0, !array.isEmpty else { return [] }

        var output: [[T]] = []
        var index = 0

        while index < array.count {
            let end = min(index + size, array.count)
            output.append(Array(array[index..<end]))
            index = end
        }

        return output
    }

    private func deduplicated<T: Hashable>(_ values: [T]) -> [T] {
        var set = Set<T>()
        var output: [T] = []

        for value in values where !set.contains(value) {
            set.insert(value)
            output.append(value)
        }

        return output
    }
}
