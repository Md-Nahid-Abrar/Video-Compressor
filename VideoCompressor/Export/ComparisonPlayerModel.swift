import AVFoundation
import Foundation

/// Two players, one for the original and one for the compressed video, driven as a pair.
@Observable
final class ComparisonPlayerModel {
    let original: AVPlayer
    let compressed: AVPlayer
    private(set) var isPlaying = false

    init(originalURL: URL, compressedURL: URL) {
        original = AVPlayer(url: originalURL)
        compressed = AVPlayer(url: compressedURL)
        // Only the compressed video is heard, so the two soundtracks don't double up.
        original.isMuted = true
        for player in [original, compressed] {
            player.automaticallyWaitsToMinimizeStalling = false
            player.actionAtItemEnd = .pause
        }
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    /// Starts both players from the same position at the same instant.
    func play() {
        let position = compressed.currentTime()
        let start = CMClockGetTime(CMClockGetHostTimeClock())
        original.setRate(1, time: position, atHostTime: start)
        compressed.setRate(1, time: position, atHostTime: start)
        isPlaying = true
    }

    func pause() {
        original.pause()
        compressed.pause()
        // Realign so the next play starts both from an identical frame.
        original.seek(to: compressed.currentTime(), toleranceBefore: .zero, toleranceAfter: .zero)
        isPlaying = false
    }

    /// Rewinds both players once playback reaches the end.
    func handlePlaybackEnded() {
        guard isPlaying else { return }
        original.pause()
        compressed.pause()
        original.seek(to: .zero)
        compressed.seek(to: .zero)
        isPlaying = false
    }

    func stop() {
        original.pause()
        compressed.pause()
        isPlaying = false
    }
}
