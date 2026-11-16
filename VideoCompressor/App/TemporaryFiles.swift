import Foundation

/// Locations for imported and exported videos inside the app's temporary directory.
nonisolated enum TemporaryFiles {
    static var importsDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: "Imports", directoryHint: .isDirectory)
    }

    static var exportsDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: "Exports", directoryHint: .isDirectory)
    }

    static func makeImportURL(pathExtension: String) throws -> URL {
        try FileManager.default.createDirectory(at: importsDirectory, withIntermediateDirectories: true)
        let ext = pathExtension.isEmpty ? "mov" : pathExtension
        return importsDirectory.appending(path: "\(UUID().uuidString).\(ext)")
    }

    static func makeExportURL() throws -> URL {
        try FileManager.default.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        let stamp = Date.now.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false).timeSeparator(.omitted).dateSeparator(.omitted))
        return exportsDirectory.appending(path: "Compressed-\(stamp)-\(UUID().uuidString.prefix(4)).mp4")
    }

    static func remove(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Clears leftovers from earlier sessions.
    static func removeAll() {
        remove(importsDirectory)
        remove(exportsDirectory)
    }
}
