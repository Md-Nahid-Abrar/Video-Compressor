import Foundation
import Testing
@testable import VideoCompressor

struct LocalizationTests {
    @Test func englishIsTheDefault() {
        #expect(AppLanguage.resolve(nil) == .english)
        #expect(AppLanguage.resolve("") == .english)
        #expect(AppLanguage.resolve("fr") == .english)
        #expect(AppLanguage.resolve("es") == .spanish)
        #expect(AppLanguage.resolve("bn") == .bengali)
    }

    @Test(arguments: [
        (AppLanguage.english, "Settings"),
        (AppLanguage.spanish, "Ajustes"),
        (AppLanguage.bengali, "সেটিংস")
    ])
    func eachLanguageHasItsOwnStrings(language: AppLanguage, expected: String) {
        #expect(String(localized: "Settings", bundle: language.bundle) == expected)
    }

    @Test func formattedStringsKeepTheirArguments() {
        for language in AppLanguage.allCases {
            let text = String(localized: "Compression failed. \("XYZ")", bundle: language.bundle)
            #expect(text.contains("XYZ"))
            let version = String(localized: "Version \("1.0") (\("7"))", bundle: language.bundle)
            #expect(version.contains("1.0") && version.contains("7"))
        }
    }
}
