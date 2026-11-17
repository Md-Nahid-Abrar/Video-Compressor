import AVKit
import SwiftUI

/// Plays one video full screen in the system player, with a button to close it.
struct VideoPlaybackView: View {
    let title: LocalizedStringKey
    @State private var player: AVPlayer
    @Environment(\.dismiss) private var dismiss

    init(title: LocalizedStringKey, url: URL) {
        self.title = title
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18), in: .circle)
                    .accessibilityIdentifier("playback.close")

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("playback.title")
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                VideoPlayer(player: player)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { player.play() }
        .onDisappear { player.pause() }
    }
}
