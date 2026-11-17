import SwiftUI

/// Shows compression progress, then the result with save and share actions.
struct ExportView: View {
    @State private var viewModel: ExportViewModel
    @State private var isCancelDialogPresented = false
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
                    ExportResultView(result: result, viewModel: viewModel)
                case .failed(let message):
                    failedContent(message)
                }
            }
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
                .foregroundStyle(Theme.accent)
                .symbolEffect(.pulse, options: .repeating)
                .accessibilityHidden(true)

            Text("Compressing Your Video")
                .font(.system(.title, weight: .black))
                .foregroundStyle(Theme.headline)
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.progress)
                        .tint(Theme.buttonEnd)
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

    // MARK: - Failed

    private func failedContent(_ message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text("Something Went Wrong")
                .font(.system(.title, weight: .black))
                .foregroundStyle(Theme.headline)
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
