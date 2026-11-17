import SwiftUI

/// Shows compression progress, then the result with save and share actions.
struct ExportView: View {
    @State private var viewModel: ExportViewModel
    @State private var isCancelDialogPresented = false
    @State private var playback: PlaybackChoice?
    @Environment(\.openURL) private var openURL
    private let router: AppRouter

    init(request: ExportRequest, services: AppServices, router: AppRouter) {
        _viewModel = State(initialValue: ExportViewModel(request: request, services: services))
        self.router = router
    }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 24) {
                switch viewModel.phase {
                case .compressing:
                    compressingContent
                case .finished(let result):
                    finishedContent(result)
                case .failed(let message):
                    failedContent(message)
                }
            }
            .padding(.top, 12)
            .animation(.smooth, value: viewModel.phase)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isCompressing)
        .toolbar {
            if case .finished = viewModel.phase {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { router.popToRoot() }
                        .accessibilityIdentifier("export.done")
                }
            }
        }
        .confirmationDialog(
            "Cancel compression?",
            isPresented: $isCancelDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Cancel Compression", role: .destructive) {
                viewModel.cancel()
                router.pop()
            }
            Button("Keep Compressing", role: .cancel) {}
        } message: {
            Text("Progress so far will be lost.")
        }
        .alert(
            "Couldn't Save Video",
            isPresented: $viewModel.isSaveErrorPresented,
            presenting: viewModel.saveError
        ) { error in
            if error == .accessDenied, let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") { openURL(url) }
            }
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.message)
        }
        .task {
            viewModel.start()
        }
    }

    private var title: LocalizedStringKey {
        switch viewModel.phase {
        case .compressing: "Compressing"
        case .finished: "Compressed"
        case .failed: "Compression Failed"
        }
    }

    // MARK: - Compressing

    private var compressingContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.accentText)
                .symbolEffect(.pulse, options: .repeating)
                .accessibilityHidden(true)

            Text("Compressing Your Video")
                .font(.system(.title, weight: .black))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.progress)
                        .tint(Theme.accentBright)
                        .scaleEffect(y: 2, anchor: .center)
                        .accessibilityIdentifier("export.progress")
                    Text(viewModel.progress.formattedPercent)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                        .accessibilityHidden(true)
                    Text(viewModel.request.preset.fullTitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            warning

            Button("Cancel", role: .cancel) {
                isCancelDialogPresented = true
            }
            .buttonStyle(.glow(.secondary))
            .accessibilityIdentifier("export.cancel")
        }
    }

    private var warning: some View {
        Label {
            Text(viewModel.continuesInBackground
                 ? "You can leave the app while this finishes, but don't force-quit it or compression will stop."
                 : "Keep the app open and on screen until this finishes, or compression will stop.")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(Theme.warning)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.warning.opacity(0.12), in: .rect(cornerRadius: 14))
        .accessibilityIdentifier("export.warning")
    }

    // MARK: - Finished

    private func finishedContent(_ result: CompressionResult) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.success)
                .symbolEffect(.bounce, value: result)
                .accessibilityHidden(true)

            Text("Video Compressed")
                .font(.system(.title, weight: .black))
                .foregroundStyle(Theme.textPrimary)
                .accessibilityIdentifier("export.finishedTitle")

            ComparisonCard(
                originalText: result.originalBytes.formattedFileSize,
                compressedText: result.compressedBytes.formattedFileSize,
                footnote: reductionText(result)
            )

            VStack(spacing: 12) {
                saveButton
                ShareLink(item: result.outputURL) {
                    Label("Share with Others", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.glow(.secondary))
                .simultaneousGesture(TapGesture().onEnded { viewModel.markShared() })
                .accessibilityIdentifier("export.share")

                if viewModel.canPlayBack {
                    Button("Play Original Video", systemImage: "play.rectangle") {
                        playback = .original
                    }
                    .buttonStyle(.glow(.secondary))
                    .accessibilityIdentifier("export.playOriginal")
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    Button("Play Compressed Video", systemImage: "play.rectangle.fill") {
                        playback = .compressed
                    }
                    .buttonStyle(.glow(.secondary))
                    .accessibilityIdentifier("export.playCompressed")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth, value: viewModel.canPlayBack)
        }
        .fullScreenCover(item: $playback) { choice in
            VideoPlaybackView(
                title: choice.title,
                url: choice == .original ? viewModel.request.sourceURL : result.outputURL
            )
        }
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

    private func reductionText(_ result: CompressionResult) -> String {
        guard result.reduction > 0 else {
            return String(localized: "This video was already well compressed.", bundle: L10n.bundle)
        }
        let percent = result.reduction.formattedPercent
        return String(localized: "\(percent) smaller", bundle: L10n.bundle)
    }

    // MARK: - Failed

    private func failedContent(_ message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text("Something Went Wrong")
                .font(.system(.title, weight: .black))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            GlassCard {
                Text(message)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("export.errorMessage")
            }

            Button("Try Again", systemImage: "arrow.clockwise") {
                viewModel.retry()
            }
            .buttonStyle(.glow)
            .accessibilityIdentifier("export.retry")
        }
    }
}
