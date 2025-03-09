import SwiftUI
import AVFoundation

// MARK: - Section View

struct SectionView: View {
    let section: MeditationSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            ForEach(section.meditations) { meditation in
                MeditationItemView(meditation: meditation)
            }
        }
    }
}

// MARK: - Meditation Item View

struct MeditationItemView: View {
    let meditation: Meditation
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    
    var body: some View {
        Button(action: {
            audioPlayer.play(meditation)
        }) {
            HStack {
                // If it's the Cutting Machinery Hour, show the logo
                if meditation.title == "Cutting Machinery Hour" {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .padding(.trailing, 8)
                }
                
                Text(meditation.title)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                
                Spacer()
                
                if audioPlayer.currentMeditation?.id == meditation.id && audioPlayer.isPlaying {
                    Image(systemName: "pause.circle")
                        .foregroundColor(.white)
                        .font(.title3)
                } else {
                    Image(systemName: "play.circle")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - Streak Counter View

struct StreakCounterView: View {
    @EnvironmentObject var streakManager: StreakManager
    @State private var isLongPressing = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Streak Days: \(streakManager.streakDays)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        decreaseStreak()
                    }) {
                        Image(systemName: "minus.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                startDecreaseTimer()
                            }
                    )
                    .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                        // This is a workaround for detecting when the long press ends
                        // The actual handling is in startDecreaseTimer
                    } onPressingChanged: { isPressing in
                        if !isPressing && isLongPressing {
                            stopTimer()
                        }
                        isLongPressing = isPressing
                    }
                    
                    Button(action: {
                        increaseStreak()
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                startIncreaseTimer()
                            }
                    )
                    .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                        // This is a workaround for detecting when the long press ends
                        // The actual handling is in startIncreaseTimer
                    } onPressingChanged: { isPressing in
                        if !isPressing && isLongPressing {
                            stopTimer()
                        }
                        isLongPressing = isPressing
                    }
                }
            }
            
            Text(streakManager.formattedLastUpdated())
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    private func decreaseStreak() {
        streakManager.updateStreak(by: -1)
    }
    
    private func increaseStreak() {
        streakManager.updateStreak(by: 1)
    }
    
    private func startDecreaseTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            decreaseStreak()
        }
    }
    
    private func startIncreaseTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            increaseStreak()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Player View

struct PlayerView: View {
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @State private var isSeeking = false
    @State private var seekPosition: Float = 0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Play/Pause button
                Button(action: {
                    audioPlayer.togglePlayPause()
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                
                // Playback info
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioPlayer.currentMeditation?.title ?? "")
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Text(formatTime(audioPlayer.currentTime))
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                        Text(" / ")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                        Text(formatTime(audioPlayer.duration))
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // Speed controls
                HStack(spacing: 8) {
                    ForEach([1.0, 1.5, 2.0, 3.0], id: \.self) { speed in
                        Button(action: {
                            audioPlayer.setPlaybackSpeed(Float(speed))
                        }) {
                            Text("\(Int(speed))x")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(audioPlayer.playbackSpeed == Float(speed) ? Color.white : Color.clear)
                                )
                                .foregroundColor(audioPlayer.playbackSpeed == Float(speed) ? Color.black : Color.white)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Progress slider
            Slider(value: Binding(
                get: {
                    isSeeking ? seekPosition : Float(audioPlayer.currentTime / max(1, audioPlayer.duration))
                },
                set: { newValue in
                    isSeeking = true
                    seekPosition = newValue
                }
            ), onEditingChanged: { editing in
                if !editing && isSeeking {
                    audioPlayer.seek(to: seekPosition)
                    isSeeking = false
                }
            })
            .accentColor(.white)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Helpers

// Keep screen on during meditation (similar to WakeLock in web)
class ScreenLockManager {
    static let shared = ScreenLockManager()
    
    private init() {}
    
    func preventScreenLock() {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func allowScreenLock() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// Network monitoring
class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private init() {
        // In a real app, initialize NWPathMonitor here
    }
    
    func startMonitoring() {
        // In a real app, use NWPathMonitor to monitor network changes
        // For this example, we'll just simulate network events
        
        // Simulated check at startup
        let isConnected = true
        
        NotificationCenter.default.post(
            name: .connectivityStatusChanged,
            object: nil,
            userInfo: ["isConnected": isConnected]
        )
    }
}