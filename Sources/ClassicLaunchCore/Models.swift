import Foundation

public struct InstalledApp: Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let bundleIdentifier: String?
    public let path: String
    public let isSystemApp: Bool

    public init(
        id: String,
        name: String,
        bundleIdentifier: String?,
        path: String,
        isSystemApp: Bool
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.isSystemApp = isSystemApp
    }
}

public enum LauncherEntry: Codable, Hashable {
    case app(String)
    case folder(String)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum EntryType: String, Codable {
        case app
        case folder
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EntryType.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        switch type {
        case .app:
            self = .app(value)
        case .folder:
            self = .folder(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .app(let value):
            try container.encode(EntryType.app, forKey: .type)
            try container.encode(value, forKey: .value)
        case .folder(let value):
            try container.encode(EntryType.folder, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    public var rawID: String {
        switch self {
        case .app(let id), .folder(let id):
            return id
        }
    }
}

public struct LauncherFolder: Codable, Hashable, Identifiable {
    public let id: String
    public var name: String
    public var appIDs: [String]
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        appIDs: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.appIDs = appIDs
        self.createdAt = createdAt
    }
}

public struct LauncherState: Codable, Hashable {
    public var schemaVersion: Int
    public var orderedEntries: [LauncherEntry]
    public var folders: [String: LauncherFolder]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        schemaVersion: Int = 1,
        orderedEntries: [LauncherEntry] = [],
        folders: [String: LauncherFolder] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.orderedEntries = orderedEntries
        self.folders = folders
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static var empty: LauncherState {
        LauncherState()
    }
}

public struct DisplayFolder: Hashable, Identifiable {
    public let id: String
    public let name: String
    public let apps: [InstalledApp]

    public init(id: String, name: String, apps: [InstalledApp]) {
        self.id = id
        self.name = name
        self.apps = apps
    }
}

public enum DisplayEntry: Hashable, Identifiable {
    case app(InstalledApp)
    case folder(DisplayFolder)

    public var id: String {
        switch self {
        case .app(let app):
            return "app:\(app.id)"
        case .folder(let folder):
            return "folder:\(folder.id)"
        }
    }

    public var title: String {
        switch self {
        case .app(let app):
            return app.name
        case .folder(let folder):
            return folder.name
        }
    }
}
