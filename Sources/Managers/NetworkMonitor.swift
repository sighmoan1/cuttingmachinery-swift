import Foundation
import Network

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                // Post notification for components that aren't using @EnvironmentObject
                NotificationCenter.default.post(
                    name: .connectivityStatusChanged,
                    object: nil,
                    userInfo: ["isConnected": path.status == .satisfied]
                )
            }
        }
        monitor.start(queue: queue)
    }
    
    func startMonitoring() {
        // Already started in init, but keep this method for API consistency
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}

// MARK: - Caching Manager for Offline Use

class AudioCacheManager {
    static let shared = AudioCacheManager()
    
    private let fileManager = FileManager.default
    private var cachesDirectory: URL? {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    private init() {
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        guard let cacheDir = cachesDirectory?.appendingPathComponent("MeditationCache") else {
            return
        }
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            do {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }
    }
    
    func cacheURLForAsset(named assetName: String) -> URL? {
        let filename = assetName.replacingOccurrences(of: "assets/", with: "")
        return cachesDirectory?.appendingPathComponent("MeditationCache/\(filename)")
    }
    
    func isCached(assetName: String) -> Bool {
        guard let cacheURL = cacheURLForAsset(named: assetName) else {
            return false
        }
        return fileManager.fileExists(atPath: cacheURL.path)
    }
    
    func cacheAsset(at remoteURL: URL, withName assetName: String, completion: @escaping (Bool) -> Void) {
        guard let cacheURL = cacheURLForAsset(named: assetName) else {
            completion(false)
            return
        }
        
        let downloadTask = URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                // If a file already exists at the destination, it will be removed
                if self.fileManager.fileExists(atPath: cacheURL.path) {
                    try self.fileManager.removeItem(at: cacheURL)
                }
                
                try self.fileManager.moveItem(at: tempURL, to: cacheURL)
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Error caching asset: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
        
        downloadTask.resume()
    }
    
    func getAssetURL(named assetName: String) -> URL? {
        // First check if it's cached
        if let cacheURL = cacheURLForAsset(named: assetName), fileManager.fileExists(atPath: cacheURL.path) {
            return cacheURL
        }
        
        // If not cached, get from the bundle
        let filename = assetName.replacingOccurrences(of: "assets/", with: "").replacingOccurrences(of: ".mp3", with: "")
        return Bundle.main.url(forResource: filename, withExtension: "mp3")
    }
    
    func clearCache() {
        guard let cacheDir = cachesDirectory?.appendingPathComponent("MeditationCache") else {
            return
        }
        
        do {
            try fileManager.removeItem(at: cacheDir)
            createCacheDirectoryIfNeeded()
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
}