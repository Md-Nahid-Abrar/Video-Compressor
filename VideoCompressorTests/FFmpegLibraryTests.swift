import FFmpegCmd
import Foundation
import Testing

struct FFmpegLibraryTests {
    @Test func libraryLoadsAndReportsItsVersion() {
        let version = String(cString: ffcmd_ffmpeg_version())
        #expect(version.hasPrefix("8.1"))
    }
}
