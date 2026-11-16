import PhotosUI
import SwiftUI

/// The main screen: pick a video, choose a compression level, see the estimate.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    private let router: AppRouter

    init(services: AppServices, router: AppRouter) {
        _viewModel = State(initialValue: HomeViewModel(services: services))
        self.router = router
    }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("Compress")
                        .foregroundStyle(Theme.textPrimary)
                    Text("Your Video")
                        .foregroundStyle(Theme.accentText)
                }
                .font(.system(.largeTitle, weight: .black))
                .multilineTextAlignment(.center)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                VideoPickerSection(
                    selection: viewModel.selection,
                    isLoading: viewModel.isLoading,
                    onSelect: viewModel.selectVideoTapped
                )

                CompressionSection(
                    isEnabled: viewModel.presetsEnabled,
                    selectedPreset: viewModel.selectedPreset,
                    estimate: viewModel.estimate(for:),
                    onChoose: { preset in
                        withAnimation(.smooth(duration: 0.35)) { viewModel.choose(preset) }
                    },
                    onChange: {
                        withAnimation(.smooth(duration: 0.35)) { viewModel.clearPreset() }
                    },
                    onExport: {
                        if let request = viewModel.exportRequest {
                            router.push(.export(request))
                        }
                    }
                )

                EstimateSection(
                    originalBytes: viewModel.selection?.metadata.fileSize,
                    estimate: viewModel.currentEstimate
                )
            }
        }
        .navigationTitle("Video Compressor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Profile", systemImage: "person.crop.circle") {
                    router.push(.profile)
                }
                .accessibilityIdentifier("home.profile")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gearshape") {
                    router.push(.settings)
                }
                .accessibilityIdentifier("home.settings")
            }
        }
        .photosPicker(
            isPresented: $viewModel.isPickerPresented,
            selection: $viewModel.pickerItem,
            matching: .videos,
            preferredItemEncoding: .current
        )
        .alert(
            viewModel.alert?.title ?? "",
            isPresented: $viewModel.isAlertPresented,
            presenting: viewModel.alert
        ) { _ in
            Button("Choose Another Video", action: viewModel.chooseAnotherVideo)
            Button("Cancel", role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(services: .live(), router: AppRouter())
    }
}
