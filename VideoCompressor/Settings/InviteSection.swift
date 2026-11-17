import SwiftUI
import UIKit

/// Copies a link the user can pass on to others.
struct InviteSection: View {
    let link: URL
    @State private var didCopy = false

    var body: some View {
        SettingsSection(title: "Invite Others") {
            Button {
                // Test phase: the privacy policy link stands in for the invite link.
                UIPasteboard.general.string = link.absoluteString
                didCopy = true
            } label: {
                Label(didCopy ? "Link Copied" : "Copy Invite Link", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.glow(didCopy ? .success : .primary))
            .accessibilityIdentifier("settings.invite")
            .task(id: didCopy) {
                guard didCopy else { return }
                try? await Task.sleep(for: .seconds(2))
                didCopy = false
            }
        }
    }
}
