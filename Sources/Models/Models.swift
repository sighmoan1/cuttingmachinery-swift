import Foundation
import AVFoundation

// MARK: - Data Models

struct MeditationSection: Identifiable {
    let id = UUID()
    let title: String
    let meditations: [Meditation]
}

struct Meditation: Identifiable {
    let id = UUID()
    let title: String
    let assetName: String
    
    // Computed property to get the URL for the asset
    var assetURL: URL? {
        // For local assets in the app bundle
        return Bundle.main.url(forResource: assetName.replacingOccurrences(of: "assets/", with: "").replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3")
    }
}

// MARK: - Data Manager

class MeditationData: ObservableObject {
    @Published var sections: [MeditationSection]
    
    init() {
        // Initialize with the same data as in the JavaScript version
        self.sections = [
            MeditationSection(
                title: "Cutting Machinery Hour",
                meditations: [
                    Meditation(title: "Cutting Machinery Hour", assetName: "assets/Hour.mp3")
                ]
            ),
            MeditationSection(
                title: "Earlier Talks",
                meditations: [
                    Meditation(title: "App Intro", assetName: "assets/01-App-Intro.mp3"),
                    Meditation(title: "Pre-Flight", assetName: "assets/02-Pre-Flight.mp3"),
                    Meditation(title: "Posture", assetName: "assets/03-Posture.mp3"),
                    Meditation(title: "What's It All For", assetName: "assets/04-Whats-It-All-For.mp3"),
                    Meditation(title: "How to Meditate", assetName: "assets/05-How-to-Meditate.mp3"),
                    Meditation(title: "Why these Phases", assetName: "assets/06-Why-these-Phases.mp3"),
                    Meditation(title: "Vinay and Lineage", assetName: "assets/07-Vinay-and-Lineage.mp3"),
                    Meditation(title: "Bad Session Guide", assetName: "assets/08-Bad-Session-Guide.mp3"),
                    Meditation(title: "Progress Guide", assetName: "assets/09-Progress-Guide.mp3"),
                    Meditation(title: "Can't Meditate", assetName: "assets/10-Cant-Meditate.mp3")
                ]
            ),
            MeditationSection(
                title: "Intermediate Talks",
                meditations: [
                    Meditation(title: "Nothing's Happening", assetName: "assets/42-Nothings-Happening.mp3"),
                    Meditation(title: "Synchronicity and Magic", assetName: "assets/43-Sync-and-Magic.mp3"),
                    Meditation(title: "Depression and Anger", assetName: "assets/44-Depression-and-Anger.mp3"),
                    Meditation(title: "Reality and Meta-Reality", assetName: "assets/45-Reality-and-Meta.mp3"),
                    Meditation(title: "Fun Stuff", assetName: "assets/46-Fun-Stuff.mp3")
                ]
            )
        ]
    }
    
    // Get a meditation by asset name
    func getMeditationByAssetName(_ assetName: String) -> Meditation? {
        for section in sections {
            if let meditation = section.meditations.first(where: { $0.assetName == assetName }) {
                return meditation
            }
        }
        return nil
    }
}

// MARK: - Audio Player Manager

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var currentMeditation: Meditation? = nil
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackSpeed: Float = 1.0
    
    private var audioPlayer: AVAudioPlayer?
    private var updateTimer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
        
        // Load last played meditation if available
        if let savedMeditationData = UserDefaults.standard.data(forKey: "lastPlayedMeditation"),
           let savedMeditation = try? JSONDecoder().decode(Meditation.self, from: savedMeditationData) {
            loadLastPlayedMeditation(savedMeditation)
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func loadLastPlayedMeditation(_ meditation: Meditation) {
        currentMeditation = meditation
        preparePlayer(for: meditation, autoPlay: false)
    }
    
    func play(_ meditation: Meditation) {
        // If it's the same meditation that's already loaded, just toggle play/pause
        if currentMeditation?.assetName == meditation.assetName && audioPlayer != nil {
            togglePlayPause()
            return
        }
        
        currentMeditation = meditation
        preparePlayer(for: meditation, autoPlay: true)
        
        // Save to UserDefaults
        if let meditationData = try? JSONEncoder().encode(meditation) {
            UserDefaults.standard.set(meditationData, forKey: "lastPlayedMeditation")
        }
    }
    
    private func preparePlayer(for meditation: Meditation, autoPlay: Bool) {
        guard let url = meditation.assetURL else {
            print("Audio file not found: \(meditation.assetName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackSpeed
            
            duration = audioPlayer?.duration ?? 0
            
            if autoPlay {
                audioPlayer?.play()
                isPlaying = true
                startTimer()
                setupNowPlaying()
            }
        } catch {
            print("Failed to initialize player: \(error)")
        }
    }
    
    func togglePlayPause() {
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
            stopTimer()
        } else {
            player.play()
            startTimer()
        }
        
        isPlaying = !isPlaying
        updateNowPlaying()
    }
    
    func seek(to percentage: Float) {
        guard let player = audioPlayer else { return }
        
        let seekTime = TimeInterval(percentage) * duration
        player.currentTime = seekTime
        currentTime = seekTime
        updateNowPlaying()
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        audioPlayer?.rate = speed
        updateNowPlaying()
    }
    
    private func startTimer() {
        stopTimer()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
    }
    
    // MARK: - Now Playing Info
    
    private func setupNowPlaying() {
        var nowPlayingInfo = [String: Any]()
        
        if let meditation = currentMeditation {
            nowPlayingInfo[MPMediaItemPropertyTitle] = meditation.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = "The Cutting Machinery"
            
            // Cover art (if available)
            if let image = UIImage(named: "AppIcon") {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                    return image
                }
            }
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackSpeed : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        setupRemoteCommandCenter()
    }
    
    private func updateNowPlaying() {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackSpeed : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Remove all targets
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.seekForwardCommand.removeTarget(nil)
        commandCenter.seekBackwardCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        // Add targets
        commandCenter.playCommand.addTarget { [weak self] _ in
            if let self = self, !self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            if let self = self, self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.seekForwardCommand.addTarget { [weak self] event in
            guard let self = self, let player = self.audioPlayer else { return .commandFailed }
            
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                let skipTime = player.currentTime + skipEvent.interval
                player.currentTime = min(skipTime, player.duration)
                self.currentTime = player.currentTime
                self.updateNowPlaying()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.seekBackwardCommand.addTarget { [weak self] event in
            guard let self = self, let player = self.audioPlayer else { return .commandFailed }
            
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                let skipTime = player.currentTime - skipEvent.interval
                player.currentTime = max(skipTime, 0)
                self.currentTime = player.currentTime
                self.updateNowPlaying()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, 
                  let player = self.audioPlayer,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            player.currentTime = positionEvent.positionTime
            self.currentTime = player.currentTime
            self.updateNowPlaying()
            return .success
        }
    }
}

// MARK: - Streak Manager

class StreakManager: ObservableObject {
    @Published var streakDays: Int = 0
    @Published var lastUpdated: Date? = nil
    
    init() {
        loadStreakData()
    }
    
    func updateStreak(by change: Int) {
        streakDays = max(0, streakDays + change)
        lastUpdated = Date()
        saveStreakData()
    }
    
    private func loadStreakData() {
        let defaults = UserDefaults.standard
        streakDays = defaults.integer(forKey: "streakDays")
        if let savedDate = defaults.object(forKey: "lastUpdated") as? Date {
            lastUpdated = savedDate
        }
    }
    
    private func saveStreakData() {
        let defaults = UserDefaults.standard
        defaults.set(streakDays, forKey: "streakDays")
        defaults.set(lastUpdated, forKey: "lastUpdated")
    }
    
    func formattedLastUpdated() -> String {
        guard let lastUpdated = lastUpdated else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Last Updated: \(formatter.string(from: lastUpdated))"
    }
}

// Required imports for Media Player functionality
import MediaPlayer