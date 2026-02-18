import AppKit
import ClassicLaunchCore
import SwiftUI
import UniformTypeIdentifiers

struct EntryDropDelegate: DropDelegate {
    let targetID: String
    let store: LauncherStore

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [UTType.plainText]).first else { return false }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
            guard let data,
                  let text = String(data: data, encoding: .utf8) else {
                return
            }

            Task { @MainActor in
                store.handleDrop(draggedID: text, onto: targetID)
            }
        }

        return true
    }
}
