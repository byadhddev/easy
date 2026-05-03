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
        static let energyPrompt     = "How full is your tank\nright now?"
        enum Energy {
            static let lowTitle     = "Running on fumes"
            static let lowDesc      = "Exhausted. Even small things feel heavy."
            static let mediumTitle  = "Getting by"
            static let mediumDesc   = "Functioning, but carrying weight."
            static let okayTitle    = "Okay enough"
            static let okayDesc     = "You have something to work with today."
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

        static let primaryCTA         = "What's been sitting with you?"
        static let acceptedQuestLabel = "You have a step waiting for you"
        static let setAsideLabel      = "things you set aside"
        static let historyLink        = "Your journey"
        static let noQuestYet         = "Nothing to carry yet.\nThat's okay."
    }

    // MARK: - Check-in (Input)
    enum CheckIn {
        static let voicePrompt      = "Just say it. Whatever it is."
        static let textPlaceholder  = "What's been on your mind..."
        static let processingLabel  = "Sitting with what you said..."
        static let switchToText     = "Type instead"
        static let switchToVoice    = "Speak instead"
    }

    // MARK: - Quest Screen
    // No "quest" label shown to user. Comfort is the center; action is secondary.
    enum Quest {
        static let comfortLabel     = "what I'm hearing"
        static let stepLabel        = "one small step"
        static let primaryCTA       = "Keep this with me"
        static let setAsideCTA      = "Set this aside for now"
        static let setAsideNote     = "It'll be here whenever you're ready."
    }

    // MARK: - Send-off (after accepting)
    enum SendOff {
        static func headline(name: String) -> String { "Go at your own pace, \(name)." }
        static let body             = "I'm holding this with you.\nNo timer. No pressure."
        static let note             = "Come back and tell me how it went — whenever that is."
        static let cta              = "I'm going"
    }

    // MARK: - Reflection (asked on return when quest is accepted)
    enum Reflection {
        static let prompt           = "How did that step go?"
        static let optionDid        = "I did it"
        static let optionTried      = "I tried"
        static let optionNotYet     = "Not yet — still holding it"
        static let optionSetAside   = "Set this aside for now"
        static let didSubtext       = "Even if it was messier than expected."
        static let triedSubtext     = "That counts. Trying is not nothing."
        static let notYetSubtext    = "No rush. It'll stay with you."
        static let setAsideSubtext  = "It'll be here when you're ready."
    }

    // MARK: - Completion
    enum Completion {
        static let headline         = "You moved something."
        static let triedHeadline    = "You showed up."
        static let subheadline      = "That wasn't nothing."
        static let reflectionPrompt = "If you want — what did that feel like?"
        static let reflectionSkip   = "That's okay. You don't have to explain it."
        static let doneButton       = "Done for now"
    }

    // MARK: - Journey
    enum Journey {
        static let title            = "Your journey"
        static let momentumNone     = "Every journey starts somewhere."
        static func momentum(count: Int, focus: String) -> String {
            count == 1
                ? "You've taken 1 step. \(focus) was the first."
                : "You've taken \(count) steps. \(focus) has been your focus."
        }
        static let categoryHeader   = "Where your energy has gone"
        static let setAsideHeader   = "Things you set aside"
        static let setAsideEmpty    = "Nothing set aside right now."
        static let reactivateCTA    = "I'm ready for this now"
        static let empty            = "Nothing here yet.\nThe journey starts with one step."
        static let timelineHeader   = "Steps you've taken"
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
