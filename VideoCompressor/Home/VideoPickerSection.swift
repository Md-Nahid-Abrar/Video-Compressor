import SwiftUI

/// Section 1: choose a video, then see an animated preview, its size and its details.
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
                            .opacity(0.9)
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glow)
                .accessibilityIdentifier("home.selectVideo")
            }
        }
    }

    private func selectedCard(_ selection: SelectedVideo) -> some View {
        let metadata = selection.metadata
        return GlassCard(padding: 14) {
            VStack(spacing: 12) {
                // Three columns: animated preview, file size, details.
                HStack(alignment: .center, spacing: 10) {
                    AnimatedPreview(frames: selection.frames)

                    Text(metadata.fileSize.formattedFileSize)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: true, vertical: false)

                    VStack(alignment: .leading, spacing: 3) {
                        detail("Resolution:", resolutionText(metadata))
                        detail("Frame rate:", frameRateText(metadata))
                        detail("Duration:", durationText(metadata))
                        detail("File Format:", metadata.formatName)
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

    private func detail(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(Theme.textSecondary)
            Text(verbatim: value)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.textPrimary)
        }
        .font(.caption)
        .lineLimit(1)
        .minimumScaleFactor(0.65)
    }

    private func resolutionText(_ metadata: VideoMetadata) -> String {
        let size = metadata.displaySize
        return "\(Int(size.width)) × \(Int(size.height))"
    }

    private func frameRateText(_ metadata: VideoMetadata) -> String {
        String(localized: "\(Int(metadata.frameRate.rounded())) fps", bundle: L10n.bundle)
    }

    private func durationText(_ metadata: VideoMetadata) -> String {
        Duration.seconds(metadata.duration).formatted(.time(pattern: .minuteSecond).locale(L10n.locale))
    }
}

#Preview {
    ZStack {
        StarfieldBackground()
        VideoPickerSection(selection: nil, isLoading: false) {}
            .padding()
    }
}
