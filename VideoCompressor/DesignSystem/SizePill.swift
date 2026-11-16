import SwiftUI

/// The orange-to-pink capsule that shows a file size.
struct SizePill: View {
    let text: String
    var isProminent = true

    var body: some View {
        Text(text)
            .font(.system(.title2, design: .rounded, weight: .heavy))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Theme.pillGradient.opacity(isProminent ? 1 : 0.35), in: .capsule)
    }
}

#Preview {
    HStack {
        SizePill(text: "314 MB")
        SizePill(text: "20 MB")
    }
    .padding()
    .background(.black)
}
