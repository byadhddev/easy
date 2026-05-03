import SwiftUI
import SwiftData

// MARK: - Root View
// App-level state machine. The flow is:
//   onboarding → home
//   home → checkIn → quest (pending) → sendOff (accepted) → home
//   home → reflection (if accepted quest exists on open) → completion → home
//   home → quest (reactivated from set_aside) → sendOff → home

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \Quest.createdAt, order: .reverse) private var quests: [Quest]

    @State private var appState: AppState = .loading

    enum AppState {
        case loading
        case onboarding
        case home
        case checkIn
        case quest(Quest)
        case sendOff(Quest)
        case reflection(Quest)
        case completion(Quest, String)   // (quest, headline)
    }

    private var profile: UserProfile? { profiles.first }

    // Quest that's been accepted but not yet reflected on
    private var pendingReflection: Quest? {
        quests.first { $0.status == .accepted }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch appState {
            case .loading:
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
                            // If there's already an accepted quest, ask for reflection first
                            if let quest = pendingReflection {
                                withAnimation(AppAnimation.fadeIn) { appState = .reflection(quest) }
                            } else {
                                withAnimation(AppAnimation.fadeIn) { appState = .checkIn }
                            }
                        },
                        onOpenQuest: { quest in
                            withAnimation(AppAnimation.fadeIn) { appState = .quest(quest) }
                        },
                        onReactivate: { quest in
                            quest.status = .pending
                            try? modelContext.save()
                            withAnimation(AppAnimation.fadeIn) { appState = .quest(quest) }
                        }
                    )
                    .onAppear {
                        // When home appears, surface reflection if quest is waiting
                        if let quest = pendingReflection {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(AppAnimation.fadeIn) { appState = .reflection(quest) }
                            }
                        }
                    }
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
                if let profile {
                    QuestView(
                        quest: quest,
                        onAccept: {
                            quest.status = .accepted
                            quest.acceptedAt = Date()
                            try? modelContext.save()
                            withAnimation(AppAnimation.fadeIn) { appState = .sendOff(quest) }
                        },
                        onSetAside: {
                            quest.status = .set_aside
                            try? modelContext.save()
                            withAnimation(AppAnimation.fadeIn) { appState = .home }
                        }
                    )
                    .environment(\.profileName, profile.name)
                }

            case .sendOff(let quest):
                if let profile {
                    SendOffView(
                        quest: quest,
                        profileName: profile.name,
                        onDismiss: {
                            withAnimation(AppAnimation.fadeIn) { appState = .home }
                        }
                    )
                }

            case .reflection(let quest):
                ReflectionView(quest: quest) { outcome in
                    switch outcome {
                    case .didIt:
                        quest.status = .completed
                        quest.completedAt = Date()
                        try? modelContext.save()
                        withAnimation(AppAnimation.fadeIn) {
                            appState = .completion(quest, AppCopy.Completion.headline)
                        }

                    case .tried:
                        quest.status = .completed
                        quest.completedAt = Date()
                        try? modelContext.save()
                        withAnimation(AppAnimation.fadeIn) {
                            appState = .completion(quest, AppCopy.Completion.triedHeadline)
                        }

                    case .notYet:
                        // Keep as accepted — still being held
                        withAnimation(AppAnimation.fadeIn) { appState = .home }

                    case .setAside:
                        quest.status = .set_aside
                        try? modelContext.save()
                        withAnimation(AppAnimation.fadeIn) { appState = .home }
                    }
                }

            case .completion(let quest, let headline):
                CompletionView(
                    quest: quest,
                    headline: headline,
                    onDone: { reflection in
                        if let text = reflection, !text.isEmpty {
                            quest.reflection = text
                            try? modelContext.save()
                        }
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
        case .sendOff:        return "sendOff"
        case .reflection:     return "reflection"
        case .completion:     return "completion"
        }
    }
}

// MARK: - Profile Name Environment Key
// Used to pass profile name into QuestView without prop drilling.

private struct ProfileNameKey: EnvironmentKey {
    static let defaultValue: String = ""
}
extension EnvironmentValues {
    var profileName: String {
        get { self[ProfileNameKey.self] }
        set { self[ProfileNameKey.self] = newValue }
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

