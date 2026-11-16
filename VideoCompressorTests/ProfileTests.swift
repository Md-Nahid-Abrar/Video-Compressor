import Foundation
import Testing
@testable import VideoCompressor

struct ProfileTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "profile-\(UUID().uuidString)")!
    }

    @Test func startsWithDefaults() {
        let viewModel = ProfileViewModel(store: ProfileStore(defaults: makeDefaults()))
        #expect(viewModel.name == ProfileStore.defaultName)
        #expect(viewModel.email == ProfileStore.defaultEmail)
    }

    @Test func editsPersistAcrossInstances() {
        let defaults = makeDefaults()
        let first = ProfileViewModel(store: ProfileStore(defaults: defaults))
        first.name = "Alex Rivera"
        first.email = "alex@example.org"

        let second = ProfileViewModel(store: ProfileStore(defaults: defaults))
        #expect(second.name == "Alex Rivera")
        #expect(second.email == "alex@example.org")
    }

    @Test(arguments: [
        ("alex@example.org", true),
        ("a.b+c@mail.example.co", true),
        ("alex", false),
        ("alex@", false),
        ("@example.org", false),
        ("alex@example", false),
        ("al ex@example.org", false),
        ("", false)
    ])
    func emailValidation(email: String, isValid: Bool) {
        let viewModel = ProfileViewModel(store: ProfileStore(defaults: makeDefaults()))
        viewModel.email = email
        #expect(viewModel.isEmailValid == isValid)
    }
}
