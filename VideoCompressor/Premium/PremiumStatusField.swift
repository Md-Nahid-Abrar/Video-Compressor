import SwiftUI

/// The strip at the top of Home. Empty for regular users; for Premium users it shows
/// the time left on the leading side and the Premium badge on the trailing side.
struct PremiumStatusField: View {
    @Environment(PremiumStore.self) private var premium

    var body: some View {
        HStack {
            if let expiry = premium.expiry {
                PremiumCountdown(expiry: expiry)
                    .transition(.opacity)
                Spacer(minLength: 8)
                PremiumBadge()
                    .transition(.opacity)
            }
        }
        // The space is always reserved, so the content below never jumps.
        .frame(maxWidth: .infinity, minHeight: 36)
        .animation(.smooth, value: premium.isActive)
    }
}
