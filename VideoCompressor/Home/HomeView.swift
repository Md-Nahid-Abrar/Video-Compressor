import PhotosUI
import SwiftUI

/// The main screen: pick a video, choose a compression level, see the estimate.
struct HomeView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @Environment(AppRouter.self) private var router
    @State private var isPromoPresented = false

    var body: some View {
        @Bindable var viewModel = viewModel
        ScreenContainer {
            VStack(spacing: 22) {
                PremiumStatusField()

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
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            HomeBottomBar(
                onSettings: { router.push(.settings) },
                onPremium: { isPromoPresented = true },
                onProfile: { router.push(.profile) }
            )
        }
        .sheet(isPresented: $isPromoPresented) {
            PromoCodeSheet()
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
