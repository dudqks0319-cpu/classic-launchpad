import ClassicLaunchCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: LauncherStore

    @FocusState private var searchFocused: Bool

    @State private var pageIndex: Int = 0
    @State private var editingMode = false
    @State private var selectedAppIDs: Set<String> = []
    @State private var openedFolderID: String?

    private let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 14), count: 7)

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 12) {
                header
                searchSection

                if store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    topLevelGrid
                } else {
                    searchGrid
                }

                footer
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onChange(of: store.pagedEntries.count) { _ in
            clampPageIndex()
        }
        .onChange(of: editingMode) { newValue in
            if !newValue {
                selectedAppIDs.removeAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            searchFocused = true
        }
        .sheet(isPresented: folderSheetPresented) {
            if let folder = currentOpenedFolder {
                FolderDetailView(
                    folder: folder,
                    editing: editingMode,
                    onRename: { newName in
                        store.renameFolder(folderID: folder.id, name: newName)
                    },
                    onRemoveApp: { appID in
                        store.removeAppFromFolder(appID: appID, folderID: folder.id)
                    },
                    onOpenApp: { app in
                        AppLauncher.launch(app)
                    },
                    onDissolve: {
                        store.dissolveFolder(folderID: folder.id)
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ClassicLaunch")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("macOS 업그레이드 이후 사라진 Launchpad 감성을 복원하는 클래식 런처")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))

                Text("개인정보 안내: 앱 목록/정렬 정보는 이 Mac 로컬에만 저장됩니다.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    store.reloadApps()
                } label: {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }

                Button {
                    editingMode.toggle()
                } label: {
                    Label(editingMode ? "완료" : "편집", systemImage: editingMode ? "checkmark.circle.fill" : "pencil")
                }

                if editingMode {
                    Button {
                        createFolderFromSelection()
                    } label: {
                        Label("선택 폴더", systemImage: "folder.badge.plus")
                    }
                    .disabled(selectedAppIDs.count < 2)

                    Button {
                        selectedAppIDs.removeAll()
                    } label: {
                        Label("선택 해제", systemImage: "xmark.circle")
                    }
                    .disabled(selectedAppIDs.isEmpty)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo.opacity(0.8))
        }
    }

    private var searchSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("앱 이름, 경로, 번들 ID 검색", text: Binding(
                    get: { store.searchQuery },
                    set: { store.setSearchQuery($0) }
                ))
                .textFieldStyle(.plain)
                .focused($searchFocused)

                if !store.searchQuery.isEmpty {
                    Button {
                        store.setSearchQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.9))
            )

            HStack {
                if let lastSync = store.lastSyncDate {
                    Text("마지막 동기화: \(lastSync.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                if let error = store.errorMessage {
                    Text(error)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.red.opacity(0.95))
                        .lineLimit(1)
                } else {
                    Text("앱 \(store.installedApps.count)개")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private var topLevelGrid: some View {
        Group {
            if store.topLevelEntries.isEmpty {
                emptyState(message: "표시할 앱이 없어요. 새로고침 후 다시 시도해 주세요.")
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 14) {
                        ForEach(currentPageEntries, id: \.id) { entry in
                            tile(for: entry)
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchGrid: some View {
        Group {
            if store.searchResults.isEmpty {
                emptyState(message: "검색 결과가 없습니다.")
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 14) {
                        ForEach(store.searchResults, id: \.id) { app in
                            AppTileView(
                                app: app,
                                selected: selectedAppIDs.contains(app.id),
                                editing: editingMode,
                                onActivate: {
                                    handleAppTap(app)
                                }
                            )
                            .contextMenu {
                                appContextMenu(app)
                            }
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            if store.searchQuery.isEmpty {
                paginationControls
            } else {
                Text("검색 결과 \(store.searchResults.count)개")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Text(editingMode ? "편집 모드: 앱 드래그로 재정렬, 앱→폴더 드롭으로 폴더에 추가" : "일반 모드: 클릭 즉시 실행 · 전역 토글 ⌥⌘L")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var paginationControls: some View {
        HStack(spacing: 10) {
            Button {
                pageIndex = max(pageIndex - 1, 0)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(pageIndex <= 0)

            let pageCount = max(store.pagedEntries.count, 1)
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == pageIndex ? .white : .white.opacity(0.35))
                    .frame(width: index == pageIndex ? 8 : 6, height: index == pageIndex ? 8 : 6)
                    .onTapGesture {
                        pageIndex = index
                    }
            }

            Button {
                pageIndex = min(pageIndex + 1, max(store.pagedEntries.count - 1, 0))
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(pageIndex >= max(store.pagedEntries.count - 1, 0))

            Text("\(pageIndex + 1)/\(max(store.pagedEntries.count, 1))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .buttonStyle(.bordered)
        .tint(.white.opacity(0.7))
    }

    @ViewBuilder
    private func tile(for entry: DisplayEntry) -> some View {
        switch entry {
        case .app(let app):
            AppTileView(
                app: app,
                selected: selectedAppIDs.contains(app.id),
                editing: editingMode,
                onActivate: {
                    handleAppTap(app)
                }
            )
            .onDrag {
                NSItemProvider(object: NSString(string: entry.id))
            }
            .onDrop(of: [UTType.plainText], delegate: EntryDropDelegate(targetID: entry.id, store: store))
            .contextMenu {
                appContextMenu(app)
            }

        case .folder(let folder):
            FolderTileView(folder: folder) {
                openedFolderID = folder.id
            }
            .onDrag {
                NSItemProvider(object: NSString(string: entry.id))
            }
            .onDrop(of: [UTType.plainText], delegate: EntryDropDelegate(targetID: entry.id, store: store))
            .contextMenu {
                folderContextMenu(folder)
            }
        }
    }

    @ViewBuilder
    private func appContextMenu(_ app: InstalledApp) -> some View {
        Button("앱 열기") {
            AppLauncher.launch(app)
        }

        if editingMode {
            Button(selectedAppIDs.contains(app.id) ? "선택 해제" : "선택") {
                toggleSelection(app.id)
            }
        }

        Divider()

        Menu("폴더에 추가") {
            ForEach(store.allFolders, id: \.id) { folder in
                Button(folder.name) {
                    store.addAppToFolder(appID: app.id, folderID: folder.id)
                }
            }
        }
        .disabled(store.allFolders.isEmpty)

        if editingMode {
            Button("상위에 고정") {
                store.ensureAppOnTopLevel(app.id)
            }
        }
    }

    @ViewBuilder
    private func folderContextMenu(_ folder: DisplayFolder) -> some View {
        Button("폴더 열기") {
            openedFolderID = folder.id
        }

        if editingMode {
            Button(role: .destructive) {
                store.dissolveFolder(folderID: folder.id)
            } label: {
                Text("폴더 해제")
            }
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.8))

            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                }
        )
    }

    private var currentPageEntries: [DisplayEntry] {
        let pages = store.pagedEntries
        guard !pages.isEmpty else { return [] }
        let safeIndex = min(max(pageIndex, 0), pages.count - 1)
        return pages[safeIndex]
    }

    private var currentOpenedFolder: DisplayFolder? {
        guard let openedFolderID else { return nil }

        for entry in store.topLevelEntries {
            if case .folder(let folder) = entry, folder.id == openedFolderID {
                return folder
            }
        }

        return nil
    }

    private var folderSheetPresented: Binding<Bool> {
        Binding(
            get: { currentOpenedFolder != nil },
            set: { shown in
                if !shown {
                    openedFolderID = nil
                }
            }
        )
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.19, blue: 0.38),
                Color(red: 0.13, green: 0.29, blue: 0.47),
                Color(red: 0.17, green: 0.16, blue: 0.29)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func handleAppTap(_ app: InstalledApp) {
        if editingMode {
            toggleSelection(app.id)
        } else {
            AppLauncher.launch(app)
        }
    }

    private func toggleSelection(_ appID: String) {
        if selectedAppIDs.contains(appID) {
            selectedAppIDs.remove(appID)
        } else {
            selectedAppIDs.insert(appID)
        }
    }

    private func createFolderFromSelection() {
        let selected = Array(selectedAppIDs)
        guard selected.count >= 2 else { return }

        store.createFolder(name: "새 폴더", appIDs: selected)
        selectedAppIDs.removeAll()
    }

    private func clampPageIndex() {
        if store.pagedEntries.isEmpty {
            pageIndex = 0
        } else {
            pageIndex = min(pageIndex, store.pagedEntries.count - 1)
        }
    }
}
