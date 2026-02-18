import AppKit
import Foundation

@MainActor
final class IconProvider {
    static let shared = IconProvider()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 600
    }

    func icon(forAppPath path: String) -> NSImage {
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 96, height: 96)
        cache.setObject(icon, forKey: key)
        return icon
    }
}
