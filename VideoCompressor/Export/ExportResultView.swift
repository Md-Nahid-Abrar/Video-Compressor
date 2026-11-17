import SwiftUI

/// What the user sees once compression finishes: both videos, the size change, and save and share.
struct ExportResultView: View {
    let result: CompressionResult
    let viewModel: ExportViewModel
    @State private var players: ComparisonPlayerModel

    init(result: CompressionResult, viewModel: ExportViewModel) {
        self.result = result
        self.viewModel = viewModel
        _players = State(initialValue: ComparisonPlayerModel(
            originalURL: viewModel.request.sourceURL,
            compressedURL: result.outputURL
        ))
    }

    var body: some View {
        VStack(spacing: 14) {
            VideoComparisonView(model: players, aspectRatio: aspectRatio)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.success)
                    .symbolEffect(.bounce, value: result)
                    .accessibilityHidden(true)
                Text("Video Compressed")
                    .foregroundStyle(Theme.headline)
                    .accessibilityIdentifier("export.finishedTitle")
            }
            .font(.system(.title2, weight: .black))

            ComparisonCard(
                originalText: result.originalBytes.formattedFileSize,
                compressedText: result.compressedBytes.formattedFileSize,
                footnote: reductionText,
                isCompact: true
            )

            HStack(spacing: 12) {
                saveButton
                ShareLink(item: result.outputURL) {
                    Label("Share with Others", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.glow(.secondary))
                .accessibilityIdentifier("export.share")
            }
        }
    }

    private var aspectRatio: CGFloat {
        let size = viewModel.request.metadata.displaySize
        guard size.width > 0, size.height > 0 else { return 16 / 9 }
        return size.width / size.height
    }

    @ViewBuilder
    private var saveButton: some View {
        switch viewModel.saveState {
        case .idle:
            Button("Save to Photos", systemImage: "square.and.arrow.down") {
                Task { await viewModel.saveToPhotos() }
            }
            .buttonStyle(.glow)
            .accessibilityIdentifier("export.save")
        case .saving:
            Button {} label: {
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Saving…")
                }
            }
            .buttonStyle(.glow)
            .disabled(true)
        case .saved:
            Button("Saved to Photos", systemImage: "checkmark") {}
                .buttonStyle(.glow(.success))
                .allowsHitTesting(false)
                .accessibilityIdentifier("export.saved")
        }
    }

    private var reductionText: String {
        guard result.reduction > 0 else {
            return String(localized: "This video was already well compressed.", bundle: L10n.bundle)
        }
        return String(localized: "\(result.reduction.formattedPercent) smaller", bundle: L10n.bundle)
    }
}
