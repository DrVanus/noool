import SwiftUI

@main
struct CryptoSageAIApp: App {
    @StateObject private var appState  = AppState()
    @StateObject private var marketVM  = MarketViewModel()    // ← make it here
    @StateObject private var newsVM    = CryptoNewsFeedViewModel() // if you need this too

    var body: some Scene {
        WindowGroup {
            ContentManagerView()
                .environmentObject(appState)
                .environmentObject(marketVM)
                .environmentObject(newsVM)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: CustomTab = .home
    @Published var isDarkMode: Bool = true
}
