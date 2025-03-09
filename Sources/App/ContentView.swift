import SwiftUI

struct ContentView: View {
    @EnvironmentObject var meditationData: MeditationData
    @EnvironmentObject var audioPlayer: AudioPlayerManager
    @EnvironmentObject var streakManager: StreakManager
    @State private var isOffline = false
    @State private var showOfflineNotification = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("primaryColor").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    Text("The Cutting Machinery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    // Documentation link
                    Link("Documentation", destination: URL(string: "https://thecuttingmachinery.netlify.app/")!)
                        .foregroundColor(.white)
                        .padding(.bottom)
                    
                    // Streak counter
                    StreakCounterView()
                        .padding()
                    
                    // Meditation list
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(meditationData.sections) { section in
                                SectionView(section: section)
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Audio player
                    if audioPlayer.currentMeditation != nil {
                        PlayerView()
                            .transition(.move(edge: .bottom))
                            .background(Color.black.opacity(0.8))
                    }
                }
                
                // Offline notification
                if showOfflineNotification {
                    VStack {
                        Spacer()
                        Text("You are currently offline. Using cached content.")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupNetworkMonitoring()
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        // In a real app, use NWPathMonitor to check network status
        // This is a simplified version for the example
        NotificationCenter.default.addObserver(forName: NSNotification.Name.connectivityStatusChanged, object: nil, queue: .main) { notification in
            if let isConnected = notification.userInfo?["isConnected"] as? Bool {
                isOffline = !isConnected
                if isOffline {
                    showOfflineNotification = true
                    // Auto-hide after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showOfflineNotification = false
                    }
                } else {
                    showOfflineNotification = false
                }
            }
        }
    }
}

// Extension for network notification name
extension NSNotification.Name {
    static let connectivityStatusChanged = NSNotification.Name("connectivityStatusChanged")
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MeditationData())
            .environmentObject(AudioPlayerManager())
            .environmentObject(StreakManager())
    }
}