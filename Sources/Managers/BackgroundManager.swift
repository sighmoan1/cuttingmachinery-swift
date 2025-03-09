import Foundation
import AVFoundation
import UIKit

// This class handles background modes and tasks similar to the service worker
class BackgroundManager {
    static let shared = BackgroundManager()
    
    // Background task identifier
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Listen for app entering background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Listen for app becoming active again
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidEnterBackground() {
        // Start background task to ensure audio continues playing
        beginBackgroundTask()
    }
    
    @objc private func applicationDidBecomeActive() {
        // End background task when app becomes active
        endBackgroundTask()
    }
    
    private func beginBackgroundTask() {
        // End any existing background task
        endBackgroundTask()
        
        // Start a new background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // Called when audio starts playing
    func audioDidStartPlaying() {
        ScreenLockManager.shared.preventScreenLock()
    }
    
    // Called when audio pauses or stops
    func audioDidStopPlaying() {
        ScreenLockManager.shared.allowScreenLock()
    }
    
    // Pre-load all audio files to make them available for offline use
    func prefetchAllAudioFiles(meditationData: MeditationData, completion: @escaping (Bool) -> Void) {
        let cacheManager = AudioCacheManager.shared
        var totalFiles = 0
        var completedFiles = 0
        var allSuccessful = true
        
        // Count total files to download
        for section in meditationData.sections {
            totalFiles += section.meditations.count
        }
        
        if totalFiles == 0 {
            completion(true)
            return
        }
        
        // Function to check if all downloads are complete
        let checkCompletion = {
            if completedFiles == totalFiles {
                completion(allSuccessful)
            }
        }
        
        // For each meditation, ensure its audio is cached
        for section in meditationData.sections {
            for meditation in section.meditations {
                if !cacheManager.isCached(assetName: meditation.assetName) {
                    // If audio isn't in cache, we need to get it from the bundle and cache it
                    if let bundleURL = Bundle.main.url(forResource: 
                                                      meditation.assetName.replacingOccurrences(of: "assets/", with: "")
                                                      .replacingOccurrences(of: ".mp3", with: ""), 
                                                      withExtension: "mp3") {
                        cacheManager.cacheAsset(at: bundleURL, withName: meditation.assetName) { success in
                            if !success {
                                allSuccessful = false
                            }
                            completedFiles += 1
                            checkCompletion()
                        }
                    } else {
                        // File not found in bundle
                        allSuccessful = false
                        completedFiles += 1
                        checkCompletion()
                    }
                } else {
                    // Already cached
                    completedFiles += 1
                    checkCompletion()
                }
            }
        }
    }
}