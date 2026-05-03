import SwiftUI
import SwiftData

@main
struct UnstuckApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, Quest.self])
    }
}
