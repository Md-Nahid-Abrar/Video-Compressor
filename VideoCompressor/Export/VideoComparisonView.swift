import AVFoundation
import Combine
import SwiftUI

/// The original and compressed videos with one shared Play button.
/// Portrait videos sit side by side; landscape videos are stacked.
struct VideoComparisonView: View {
    let model: ComparisonPlayerModel
    /// Width divided by height, as shown on screen.
    let aspectRatio: CGFloat

    private var isPortrait: Bool { aspectRatio <= 1 }

    var body: some View {
        VStack(spacing: 10) {
            let layout = isPortrait
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 10))
                : AnyLayout(VStackLayout(spacing: 8))
            layout {
                pane("Original", player: model.original)
                pane("Compressed", player: model.compressed)
            }

            Button {
                model.toggle()
            } label: {
                Label(model.isPlaying ? "Pause" : "Play", systemImage: model.isPlaying ? "pause.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.glow)
            .frame(maxWidth: 220)
            .accessibilityIdentifier("export.play")
            .accessibilityHint("Plays both videos at the same time")
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: AVPlayerItem.didPlayToEndTimeNotification)
                .receive(on: DispatchQueue.main)
        ) { _ in
            model.handlePlaybackEnded()
        }
        .onDisappear {
            model.stop()
        }
    }

    private func pane(_ title: LocalizedStringKey, player: AVPlayer) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        // Capping the width (rather than the height) keeps the frame hugging the picture.
        let maxHeight: CGFloat = isPortrait ? 270 : 136
        return VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            PlayerLayerView(player: player)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipShape(shape)
                .overlay { shape.strokeBorder(Theme.cardStroke, lineWidth: 1) }
                .frame(maxWidth: maxHeight * aspectRatio)
                .accessibilityLabel(title)
        }
        .frame(maxWidth: .infinity)
    }
}
