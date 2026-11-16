import Foundation

nonisolated extension Int64 {
    /// A short file-size string such as "25 MB".
    var formattedFileSize: String {
        formatted(.byteCount(style: .file))
    }
}
