import SwiftUI
import SwiftData

// MARK: - Root View
// Decides: show onboarding (first launch) or home screen.
// Manages the app-level navigation state machine.

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var appState: AppState = .loading

    enum AppState {
        case loading
        case onboarding
        case home
        case checkIn
        case quest(Quest)
        case completion(Quest)
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch appState {
            case .loading:
                // Splash — wordmark fades in
                SplashView()
                    .onAppear { resolveInitialState() }

            case .onboarding:
                OnboardingFlow { newProfile in
                    modelContext.insert(newProfile)
                    try? modelContext.save()
                    withAnimation(AppAnimation.fadeIn) { appState = .home }
                }

            case .home:
                if let profile {
                    HomeView(
                        profile: profile,
                        onCheckIn: {
                            withAnimation(AppAnimation.fadeIn) { appState = .checkIn }
                        },
                        onOpenQuest: { quest in
                            withAnimation(AppAnimation.fadeIn) { appState = .quest(quest) }
                        }
                    )
                }

            case .checkIn:
                if let profile {
                    CheckInView(
                        userProfile: profile,
                        onQuestGenerated: { response in
                            let quest = Quest(
                                stepTitle: response.stepTitle,
                                comfortParagraph: response.comfort,
                                actionStep: response.step,
                                userInput: ""
                            )
                            modelContext.insert(quest)
                            try? modelContext.save()
                            withAnimation(AppAnimation.fadeIn) { appState = .quest(quest) }
                        },
                        onDismiss: {
                            withAnimation(AppAnimation.fadeIn) { appState = .home }
                        }
                    )
                }

            case .quest(let quest):
                QuestView(
                    quest: quest,
                    onComplete: {
                        withAnimation(AppAnimation.fadeIn) { appState = .completion(quest) }
                    },
                    onSkip: {
                        quest.status = .skipped
                        try? modelContext.save()
                        withAnimation(AppAnimation.fadeIn) { appState = .home }
                    }
                )

            case .completion(let quest):
                CompletionView(
                    quest: quest,
                    onDone: { reflection in
                        quest.status = .completed
                        quest.completedAt = Date()
                        quest.reflection = reflection
                        try? modelContext.save()
                        withAnimation(AppAnimation.fadeIn) { appState = .home }
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .animation(AppAnimation.fadeIn, value: appState.id)
    }

    private func resolveInitialState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(AppAnimation.fadeIn) {
                appState = (profiles.first?.hasCompletedOnboarding == true) ? .home : .onboarding
            }
        }
    }
}

extension RootView.AppState {
    var id: String {
        switch self {
        case .loading:        return "loading"
        case .onboarding:     return "onboarding"
        case .home:           return "home"
        case .checkIn:        return "checkIn"
        case .quest:          return "quest"
        case .completion:     return "completion"
        }
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("unstuck")
                .font(.appHero)
                .foregroundStyle(Color.appTextPrimary)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.8), value: appeared)
                .onAppear { appeared = true }
        }
    }
}
