import SwiftUI

@main
struct TheCuttingMachineryApp: App {
    @StateObject var meditationData = MeditationData()
    @StateObject var audioPlayer = AudioPlayerManager()
    @StateObject var streakManager = StreakManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(meditationData)
                .environmentObject(audioPlayer)
                .environmentObject(streakManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupAppearance()
                }
        }
    }
    
    private func setupAppearance() {
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("primaryColor"))
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}