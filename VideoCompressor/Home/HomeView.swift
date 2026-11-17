import PhotosUI
import SwiftUI

/// The main screen: pick a video, choose a compression level, see the estimate.
struct HomeView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @Environment(AppRouter.self) private var router
    @Environment(PremiumStore.self) private var premium
    @State private var isPromoPresented = false
    @State private var isCancelPremiumPresented = false

    var body: some View {
        @Bindable var viewModel = viewModel
        ScreenContainer {
            VStack(spacing: 20) {
                PremiumStatusField()

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
        .safeAreaInset(edge: .bottom) {
            HomeBottomBar(
                isPremiumActive: premium.isActive,
                onSettings: { router.push(.settings) },
                onPremium: {
                    if premium.isActive {
                        isCancelPremiumPresented = true
                    } else {
                        isPromoPresented = true
                    }
                },
                onProfile: { router.push(.profile) }
            )
        }
        .sheet(isPresented: $isPromoPresented) {
            PromoCodeSheet()
        }
        .alert("Cancel Premium?", isPresented: $isCancelPremiumPresented) {
            Button("Cancel Premium", role: .destructive) {
                premium.cancel()
            }
            Button("Keep Premium", role: .cancel) {}
        } message: {
            Text("Premium will end now. You can enter a promo code again later.")
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
