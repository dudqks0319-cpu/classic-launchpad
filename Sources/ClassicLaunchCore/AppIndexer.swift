import Foundation

public protocol AppIndexing {
    func scanInstalledApps() throws -> [InstalledApp]
}

public final class DefaultAppIndexer: AppIndexing {
    private let fileManager = FileManager.default
    private let roots: [URL]
    private let maxDepth: Int

    public init(maxDepth: Int = 3) {
        self.maxDepth = maxDepth

        var paths: [String] = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities"
        ]

        let userApplications = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Applications", isDirectory: true)
            .path

        paths.append(userApplications)

        self.roots = paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    public func scanInstalledApps() throws -> [InstalledApp] {
        var appBundleURLs = Set<URL>()
        for root in roots where fileManager.fileExists(atPath: root.path) {
            collectAppBundles(at: root, depth: 0, result: &appBundleURLs)
        }

        var deduplicatedByID: [String: InstalledApp] = [:]

        for appURL in appBundleURLs {
            let path = appURL.path
            let bundle = Bundle(url: appURL)
            let bundleID = bundle?.bundleIdentifier
            let displayName = (
                bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ) ?? (
                bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ) ?? appURL.deletingPathExtension().lastPathComponent

            let appID = bundleID ?? "path:\(path)"
            let app = InstalledApp(
                id: appID,
                name: displayName,
                bundleIdentifier: bundleID,
                path: path,
                isSystemApp: path.hasPrefix("/System/")
            )

            if let existing = deduplicatedByID[appID] {
                // /Applications 쪽을 우선시해서 사용자 설치 앱을 더 자주 노출
                if existing.path.hasPrefix("/System/") && !path.hasPrefix("/System/") {
                    deduplicatedByID[appID] = app
                }
            } else {
                deduplicatedByID[appID] = app
            }
        }

        return deduplicatedByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func collectAppBundles(at url: URL, depth: Int, result: inout Set<URL>) {
        guard depth <= maxDepth else { return }

        guard let items = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isApplicationKey, .isPackageKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for item in items {
            if item.pathExtension.lowercased() == "app" {
                result.insert(item)
                continue
            }

            guard depth < maxDepth else { continue }

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }

            collectAppBundles(at: item, depth: depth + 1, result: &result)
        }
    }
}
