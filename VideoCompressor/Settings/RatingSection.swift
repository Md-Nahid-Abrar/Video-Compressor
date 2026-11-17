import SwiftUI

/// Five stars that light up as the user picks a rating.
struct RatingSection: View {
    @State private var rating = 0

    var body: some View {
        SettingsSection(title: "Provide Rating") {
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    let isLit = star <= rating
                    Button {
                        withAnimation(.smooth(duration: 0.2)) { rating = star }
                    } label: {
                        Image(systemName: isLit ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(isLit ? Theme.headline : Theme.textSecondary)
                            .shadow(color: Theme.headline.opacity(isLit ? 0.85 : 0), radius: 8)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(star) stars")
                    .accessibilityAddTraits(isLit ? .isSelected : [])
                    .accessibilityIdentifier("settings.star.\(star)")
                }
            }
            .frame(maxWidth: .infinity)

            Button("Submit Rating", systemImage: "star.bubble") {
                // Placeholder for the test phase: submitting does nothing yet.
            }
            .buttonStyle(.glow)
            .disabled(rating == 0)
            .accessibilityIdentifier("settings.submitRating")
        }
    }
}
