import SwiftUI

/// The area at the top of Home. Empty for regular users; for Premium users it shows the
/// countdown, the Premium badge and the Hardware Acceleration switch.
struct PremiumStatusField: View {
    @Environment(PremiumStore.self) private var premium
    @AppStorage(StorageKey.hardwareAcceleration) private var isHardwareAccelerationOn = false

    var body: some View {
        VStack(spacing: 10) {
            if let expiry = premium.expiry {
                HStack {
                    PremiumCountdown(expiry: expiry)
                    Spacer(minLength: 8)
                    PremiumBadge()
                }
                GlassCard(padding: 12) {
                    // Placeholder for the test phase: the switch is stored but changes nothing yet.
                    Toggle(isOn: $isHardwareAccelerationOn) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hardware Acceleration")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Running on GPU for faster processing time")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "arrowshape.up.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .tint(Theme.success)
                    .accessibilityIdentifier("premium.hardwareAcceleration")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        // The space is always reserved, so the sections below never jump.
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .top)
        .animation(.smooth, value: premium.isActive)
    }
}
