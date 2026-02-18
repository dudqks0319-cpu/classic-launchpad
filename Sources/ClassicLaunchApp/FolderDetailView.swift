import ClassicLaunchCore
import SwiftUI

struct FolderDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let folder: DisplayFolder
    let editing: Bool
    let onRename: (String) -> Void
    let onRemoveApp: (String) -> Void
    let onOpenApp: (InstalledApp) -> Void
    let onDissolve: () -> Void

    @State private var draftName: String = ""

    var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
                    ForEach(folder.apps) { app in
                        AppTileView(
                            app: app,
                            selected: false,
                            editing: editing,
                            onActivate: {
                                if editing {
                                    onRemoveApp(app.id)
                                } else {
                                    onOpenApp(app)
                                }
                            }
                        )
                        .contextMenu {
                            Button("앱 열기") { onOpenApp(app) }
                            Divider()
                            Button("폴더에서 빼기") { onRemoveApp(app.id) }
                        }
                    }
                }
                .padding(.top, 4)
            }

            HStack {
                if editing {
                    Button(role: .destructive) {
                        onDissolve()
                        dismiss()
                    } label: {
                        Text("폴더 해제")
                    }
                }

                Spacer()

                Button("닫기") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 700, minHeight: 480)
        .onAppear {
            draftName = folder.name
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if editing {
                    TextField("폴더 이름", text: $draftName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            commitRename()
                        }

                    Button("저장") {
                        commitRename()
                    }
                } else {
                    Text(folder.name)
                        .font(.system(size: 22, weight: .bold))
                }

                Spacer()

                Text("\(folder.apps.count)개 앱")
                    .foregroundStyle(.secondary)
            }

            Text(editing ? "편집 모드: 앱을 누르면 폴더 밖으로 꺼냅니다." : "앱을 눌러 바로 실행하세요.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private func commitRename() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onRename(trimmed)
    }
}
