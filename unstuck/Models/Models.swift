import SwiftData
import Foundation

// MARK: - UserProfile
@Model
final class UserProfile {
    var name: String
    var energyLevel: EnergyLevel
    var selectedCategories: [QuestCategory]
    var createdAt: Date
    var hasCompletedOnboarding: Bool

    init(
        name: String,
        energyLevel: EnergyLevel = .medium,
        selectedCategories: [QuestCategory] = [],
        hasCompletedOnboarding: Bool = false
    ) {
        self.name = name
        self.energyLevel = energyLevel
        self.selectedCategories = selectedCategories
        self.createdAt = Date()
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

// MARK: - Quest
@Model
final class Quest {
    var id: UUID
    var stepTitle: String
    var comfortParagraph: String
    var actionStep: String
    var status: QuestStatus
    var reflection: String?
    var userInput: String        // What the user told the app
    var category: QuestCategory
    var createdAt: Date
    var completedAt: Date?

    init(
        stepTitle: String,
        comfortParagraph: String,
        actionStep: String,
        userInput: String,
        category: QuestCategory = .unclear
    ) {
        self.id = UUID()
        self.stepTitle = stepTitle
        self.comfortParagraph = comfortParagraph
        self.actionStep = actionStep
        self.userInput = userInput
        self.category = category
        self.status = .active
        self.createdAt = Date()
    }
}

// MARK: - Supporting Enums

enum EnergyLevel: String, Codable, CaseIterable {
    case low    = "low"
    case medium = "medium"
    case okay   = "okay"

    var displayName: String {
        switch self {
        case .low:    return AppCopy.Onboarding.Energy.lowTitle
        case .medium: return AppCopy.Onboarding.Energy.mediumTitle
        case .okay:   return AppCopy.Onboarding.Energy.okayTitle
        }
    }

    var icon: String {
        switch self {
        case .low:    return "🕯"
        case .medium: return "🪔"
        case .okay:   return "💡"
        }
    }
}

enum QuestCategory: String, Codable, CaseIterable {
    case health       = "health"
    case conversation = "conversation"
    case work         = "work"
    case home         = "home"
    case unclear      = "unclear"

    var displayName: String {
        switch self {
        case .health:       return AppCopy.Onboarding.Categories.health
        case .conversation: return AppCopy.Onboarding.Categories.conversation
        case .work:         return AppCopy.Onboarding.Categories.work
        case .home:         return AppCopy.Onboarding.Categories.home
        case .unclear:      return AppCopy.Onboarding.Categories.unclear
        }
    }

    var emoji: String {
        switch self {
        case .health:       return "🏥"
        case .conversation: return "💬"
        case .work:         return "💼"
        case .home:         return "🏠"
        case .unclear:      return "🌀"
        }
    }
}

enum QuestStatus: String, Codable {
    case active    = "active"
    case skipped   = "skipped"
    case completed = "completed"
}
