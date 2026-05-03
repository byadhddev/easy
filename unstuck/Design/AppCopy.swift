import Foundation

// MARK: - App Copywriting
// All user-facing strings live here. Edit copy here — never hardcode in views.
// Voice: calm, specific, honest. Never minimizing. Never cheerleading.

enum AppCopy {

    // MARK: - Welcome Flow
    enum Welcome {
        static let line1 = "That thing you've been\nputting off?"
        static let line2 = "It's not laziness.\nIt's weight."
        static let line3 = "Let's move just\none piece of it."
        static let cta   = "I'm ready"
    }

    // MARK: - Onboarding
    enum Onboarding {
        // Step 1 — Name
        static let namePrompt       = "What do I call you?"
        static let namePlaceholder  = "Your name"

        // Step 2 — Categories
        static let categoryPrompt   = "What kind of thing has been\nsitting with you?"
        static let categoryNote     = "This helps me understand you — nothing is sent anywhere."
        enum Categories {
            static let health       = "Health"
            static let conversation = "A conversation"
            static let work         = "Work"
            static let home         = "Home"
            static let unclear      = "Something unclear"
        }

        // Step 3 — Energy
        static let energyPrompt     = "How much do you have in\nthe tank right now?"
        enum Energy {
            static let low          = "Running on fumes"
            static let medium       = "Getting by"
            static let okay         = "Okay enough"
        }

        static let continueButton   = "Continue"
        static let finishButton     = "Let's go"
    }

    // MARK: - Home Screen
    enum Home {
        static func greeting(name: String, hour: Int) -> String {
            switch hour {
            case 5..<12:  return "Good morning, \(name).\nWhat's been sitting heaviest?"
            case 12..<17: return "Hey \(name).\nOne thing at a time. What's on your mind?"
            case 17..<21: return "Evening, \(name).\nWhat's still sitting with you?"
            default:      return "Still up, \(name)?\nLet's clear one thing before you sleep."
            }
        }

        static let primaryCTA       = "Tell me what's going on"
        static let activeQuestLabel = "You have something waiting"
        static let historyLink      = "Things you've faced"
        static let noQuestYet       = "Nothing to carry yet.\nThat's okay."
    }

    // MARK: - Check-in (Input)
    enum CheckIn {
        static let voicePrompt      = "Just say it. Whatever it is."
        static let textPlaceholder  = "What's been on your mind..."
        static let processingLabel  = "Thinking about what you need..."
        static let switchToText     = "Type instead"
        static let switchToVoice    = "Speak instead"
    }

    // MARK: - Quest Screen
    enum Quest {
        static let label            = "your quest"
        static let primaryCTA       = "I'll try this"
        static let notReadyCTA      = "Not ready yet"
        static let dismissMessage   = "Okay. It'll be here when you're ready."
        static let timerSuggestion  = "Want 5 minutes to do this?"
        static let timerStart       = "Start 5-minute timer"
    }

    // MARK: - Completion
    enum Completion {
        static let headline         = "You did it."
        static let subheadline      = "That wasn't nothing."
        static let reflectionPrompt = "If you want — what did that feel like?"
        static let reflectionSkip   = "That's okay. You don't have to explain it."
        static let doneButton       = "Done for now"
    }

    // MARK: - History
    enum History {
        static let title            = "Things you've faced."
        static let empty            = "Nothing here yet — and that's okay."
        static let sectionToday     = "Today"
        static let sectionYesterday = "Yesterday"
    }

    // MARK: - Generic / Shared
    enum Shared {
        static let back             = "Back"
        static let skip             = "Skip"
        static let done             = "Done"
        static let tryAgain         = "Try again"
        static let errorGeneric     = "Something went quiet. Try again in a moment."
        static let micPermission    = "Microphone access lets you speak your thoughts instead of typing them."
        static let micDenied        = "You can still type your thoughts — or allow microphone access in Settings."
    }
}
