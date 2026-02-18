import Foundation

public protocol LauncherStatePersisting {
    func loadState() throws -> LauncherState?
    func saveState(_ state: LauncherState) throws
}

public final class FileLauncherStatePersistence: LauncherStatePersisting {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func loadState() throws -> LauncherState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(LauncherState.self, from: data)
    }

    public func saveState(_ state: LauncherState) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }

    public static func `default`() -> FileLauncherStatePersistence {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)

        let fileURL = appSupport
            .appendingPathComponent("ClassicLaunch", isDirectory: true)
            .appendingPathComponent("launcher-state.json", isDirectory: false)

        return FileLauncherStatePersistence(fileURL: fileURL)
    }
}
