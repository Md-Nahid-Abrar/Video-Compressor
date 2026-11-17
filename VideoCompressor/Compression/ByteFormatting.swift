import Foundation

nonisolated extension Int64 {
    /// A short file-size string such as "25 MB", in the app's language.
    var formattedFileSize: String {
        formatted(.byteCount(style: .file).locale(L10n.locale))
    }
}

nonisolated extension Double {
    /// A whole-number percentage such as "80%", in the app's language.
    var formattedPercent: String {
        formatted(.percent.precision(.fractionLength(0)).locale(L10n.locale))
    }
}
