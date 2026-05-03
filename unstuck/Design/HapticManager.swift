import UIKit

// MARK: - Haptic Manager
// Centralized haptic feedback — one place to tune the entire tactile feel of the app.
// Each moment is intentionally named for its emotional context, not just its intensity.

enum Haptic {

    /// Light acknowledgment — e.g., tapping the mic to start listening
    static func softTouch() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Meaningful commitment — e.g., "I'll try this" on a quest
    static func commit() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// No shame, no judgment — e.g., "Not ready yet" or skip
    static func gentle() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Quest complete — the most significant moment in the app
    static func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Quest generated — a new possibility appearing
    static func questArrived() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// Selection change — category/energy picker
    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
