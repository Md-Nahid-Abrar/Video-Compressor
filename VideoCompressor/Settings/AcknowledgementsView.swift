import FFmpegCmd
import SwiftUI

/// Credits FFmpeg and shows its licence, as the LGPL requires.
struct AcknowledgementsView: View {
    @Environment(\.dismiss) private var dismiss

    private let version = String(cString: ffcmd_ffmpeg_version())
    private let licenceText: String = {
        guard let url = Bundle.main.url(forResource: "FFmpeg-LGPL-2.1", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text
    }()

    var body: some View {
        NavigationStack {
            ScreenContainer {
                VStack(alignment: .leading, spacing: 16) {
                    Text("FFmpeg \(version)")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Video compression in this app is performed by FFmpeg, which is licensed under the GNU Lesser General Public License, version 2.1 or later. FFmpeg is included as a separate library that can be replaced.")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)

                    Link(destination: AppConfig.ffmpegSourceURL) {
                        Label("FFmpeg source code", systemImage: "arrow.down.doc.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.accentText)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .accessibilityIdentifier("acknowledgements.source")

                    GlassCard(padding: 14) {
                        Text(verbatim: licenceText)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("acknowledgements.licence")
                    }
                }
            }
            .navigationTitle("Acknowledgements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("acknowledgements.done")
                }
            }
        }
    }
}

#Preview {
    AcknowledgementsView()
}
