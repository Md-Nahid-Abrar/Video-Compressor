import CoreTransferable
import UniformTypeIdentifiers

/// A video handed over by the Photos picker, copied into the app's temporary directory.
nonisolated struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let destination = try TemporaryFiles.makeImportURL(pathExtension: received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMovie(url: destination)
        }
    }
}
