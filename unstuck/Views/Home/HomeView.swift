import SwiftUI
import SwiftData

// MARK: - Home View

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quest.createdAt, order: .reverse) private var quests: [Quest]

    var profile: UserProfile
    var onCheckIn: () -> Void
    var onOpenQuest: (Quest) -> Void
    var onReactivate: (Quest) -> Void

    @State private var appeared = false
    @State private var showJourney = false

    private var acceptedQuest: Quest? {
        quests.first { $0.status == .accepted }
    }

    private var pendingQuest: Quest? {
        quests.first { $0.status == .pending }
    }

    private var setAsideCount: Int {
        quests.filter { $0.status == .set_aside }.count
    }

    private var hasJourneyContent: Bool {
        quests.contains { $0.status == .completed || $0.status == .set_aside }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return AppCopy.Home.greeting(name: profile.name, hour: hour)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(greeting)
                    .font(.appTitle)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineSpacing(6)
                    .padding(.top, AppSpacing.xxl)
                    .padding(.horizontal, AppSpacing.lg)
                    .fadeUp(appear: appeared, delay: 0)

                Spacer()

                VStack(spacing: AppSpacing.md) {
                    // Primary CTA — only show if no accepted quest in flight
                    if acceptedQuest == nil {
                        Button {
                            Haptic.softTouch()
                            onCheckIn()
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.appBackground)
                                Text(AppCopy.Home.primaryCTA)
                                    .font(.appCTA)
                                    .foregroundStyle(Color.appBackground)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md + 2)
                            .background(Color.appAmber)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppSpacing.lg)
                        .fadeUp(appear: appeared, delay: 0.15)
                    }

                    // Accepted quest card — "being held for you"
                    if let quest = acceptedQuest {
                        AcceptedQuestCard(quest: quest) {
                            onOpenQuest(quest)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .fadeUp(appear: appeared, delay: 0.15)
                    }

                    // Pending quest card (not yet accepted)
                    if acceptedQuest == nil, let quest = pendingQuest {
                        QuestCardPreview(quest: quest) {
                            onOpenQuest(quest)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .fadeUp(appear: appeared, delay: 0.2)
                    }
                }

                Spacer().frame(height: AppSpacing.xl)

                // Bottom links
                VStack(spacing: AppSpacing.md) {
                    if setAsideCount > 0 {
                        Button {
                            showJourney = true
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "tray")
                                    .font(.system(size: 13, weight: .medium))
                                Text("\(setAsideCount) \(AppCopy.Home.setAsideLabel)")
                                    .font(.appLabel)
                            }
                            .foregroundStyle(Color.appTextDim)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppSpacing.lg)
                        .fadeUp(appear: appeared, delay: 0.25)
                    }

                    if hasJourneyContent {
                        Button {
                            showJourney = true
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .medium))
                                Text(AppCopy.Home.historyLink)
                                    .font(.appLabel)
                            }
                            .foregroundStyle(Color.appTextDim)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xxxl)
                        .fadeUp(appear: appeared, delay: 0.3)
                    }
                }
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .dynamicTypeSize(.small ... .accessibility2)
        .sheet(isPresented: $showJourney) {
            JourneyView(onReactivate: onReactivate)
        }
    }
}

// MARK: - Accepted Quest Card
// Shown when user has accepted a step and been sent off.
// Warm, held — not a task card.

private struct AcceptedQuestCard: View {
    let quest: Quest
    let onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Soft pulsing amber dot
                Circle()
                    .fill(Color.appAmber)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse ? 1.3 : 1.0)
                    .opacity(pulse ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppCopy.Home.acceptedQuestLabel)
                        .font(.appCaption)
                        .foregroundStyle(Color.appAmber.opacity(0.8))

                    Text(quest.stepTitle)
                        .font(.appLabel)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appTextDim)
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(Color.appAmber.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }
}

