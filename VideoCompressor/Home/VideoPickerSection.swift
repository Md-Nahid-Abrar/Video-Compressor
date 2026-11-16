import SwiftUI

/// Section 1: choose a video, then see what was chosen.
struct VideoPickerSection: View {
    let selection: SelectedVideo?
    let isLoading: Bool
    let onSelect: () -> Void

    var body: some View {
        Group {
            if isLoading {
                GlassCard {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Preparing video…")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .frame(minHeight: 96)
                }
                .accessibilityIdentifier("home.loading")
            } else if let selection {
                selectedCard(selection)
            } else {
                Button(action: onSelect) {
                    VStack(spacing: 8) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 34, weight: .semibold))
                        Text("Select Video")
                        Text("Choose from your Photos library")
                            .font(.footnote.weight(.regular))
                            .opacity(0.85)
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glow)
                .accessibilityIdentifier("home.selectVideo")
            }
        }
    }

    private func selectedCard(_ selection: SelectedVideo) -> some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    thumbnail(selection)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selection.metadata.fileSize.formattedFileSize)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(detailText(selection.metadata))
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Text(durationText(selection.metadata))
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("home.selectedVideo")

                Button("Change Video", systemImage: "arrow.triangle.2.circlepath", action: onSelect)
                    .buttonStyle(.glow(.secondary))
                    .accessibilityIdentifier("home.changeVideo")
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ selection: SelectedVideo) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        Group {
            if let image = selection.thumbnail {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 96, height: 96)
        .background(Theme.cardFill)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Theme.cardStroke, lineWidth: 1) }
    }

    private func detailText(_ metadata: VideoMetadata) -> String {
        let size = metadata.displaySize
        let fps = Int(metadata.frameRate.rounded())
        return "\(Int(size.width)) × \(Int(size.height)) · \(fps) fps"
    }

    private func durationText(_ metadata: VideoMetadata) -> String {
        Duration.seconds(metadata.duration).formatted(.time(pattern: .minuteSecond))
    }
}

#Preview {
    ZStack {
        StarfieldBackground()
        VideoPickerSection(selection: nil, isLoading: false) {}
            .padding()
    }
}
