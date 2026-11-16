import Testing
@testable import VideoCompressor

struct FormatValidatorTests {
    @Test(arguments: ["mp4", "mov", "m4v", "MOV"], ["avc1", "avc3", "hvc1", "hev1", "dvh1", "dvhe"])
    func acceptsAppleStandardFormats(container: String, codec: String) {
        #expect(FormatValidator.validate(containerExtension: container, codec: codec) == nil)
    }

    @Test(arguments: ["mkv", "avi", "webm", "wmv", ""])
    func rejectsOtherContainers(container: String) {
        #expect(FormatValidator.validate(containerExtension: container, codec: "avc1") == .unsupportedContainer(container))
    }

    @Test(arguments: ["apcn", "av01", "vp09", "jpeg", "mp4v"])
    func rejectsOtherCodecs(codec: String) {
        #expect(FormatValidator.validate(containerExtension: "mov", codec: codec) == .unsupportedCodec(codec))
    }

    @Test func rejectsFilesWithoutVideo() {
        #expect(FormatValidator.validate(containerExtension: "mp4", codec: nil) == .noVideoTrack)
        #expect(FormatValidator.validate(containerExtension: "mp4", codec: "") == .noVideoTrack)
    }

    @Test func rejectsProtectedContent() {
        #expect(FormatValidator.validate(containerExtension: "mp4", codec: "avc1", hasProtectedContent: true) == .protectedContent)
    }

    @Test func everyRejectionHasAMessage() {
        let rejections: [FormatRejection] = [.unsupportedContainer("mkv"), .unsupportedCodec("av01"), .noVideoTrack, .protectedContent]
        for rejection in rejections {
            #expect(!rejection.message.isEmpty)
        }
    }
}
