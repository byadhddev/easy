import SwiftUI
import SwiftData

// MARK: - Home View

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quest.createdAt, order: .reverse) private var quests: [Quest]

    var profile: UserProfile
    var onCheckIn: () -> Void
    var onOpenQuest: (Quest) -> Void

    @State private var appeared = false
    @State private var showHistory = false

    private var activeQuest: Quest? {
        quests.first { $0.status == .active }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return AppCopy.Home.greeting(name: profile.name, hour: hour)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Greeting
                Text(greeting)
                    .font(.appTitle)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineSpacing(6)
                    .padding(.top, AppSpacing.xxl)
                    .padding(.horizontal, AppSpacing.lg)
                    .fadeUp(appear: appeared, delay: 0)

                Spacer()

                // Primary check-in button
                VStack(spacing: AppSpacing.md) {
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

                    // Active quest preview
                    if let quest = activeQuest {
                        QuestCardPreview(quest: quest) {
                            onOpenQuest(quest)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .fadeUp(appear: appeared, delay: 0.2)
                    }
                }

                Spacer().frame(height: AppSpacing.xl)

                // History link
                if quests.contains(where: { $0.status == .completed }) {
                    Button {
                        showHistory = true
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "clock")
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
        .onAppear { withAnimation { appeared = true } }
        .dynamicTypeSize(.small ... .accessibility2)
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
    }
}

// MARK: - History View

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    // Fetch all quests sorted by creation date; filter to completed in computed property
    // (avoids SwiftData #Predicate limitations with Codable enums)
    @Query(sort: \Quest.createdAt, order: .reverse) private var allQuests: [Quest]

    private var completedQuests: [Quest] {
        allQuests.filter { $0.status == .completed }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                Group {
                    if completedQuests.isEmpty {
                        Text(AppCopy.History.empty)
                            .font(.appBody)
                            .foregroundStyle(Color.appTextDim)
                            .multilineTextAlignment(.center)
                            .padding(AppSpacing.xl)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(groupedQuests, id: \.0) { section, quests in
                                    sectionHeader(section)
                                    ForEach(quests) { quest in
                                        QuestHistoryRow(quest: quest)
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                }
            }
            .navigationTitle(AppCopy.History.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppCopy.Shared.done) { dismiss() }
                        .font(.appCTA)
                        .foregroundStyle(Color.appAmber)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.appCaption)
            .foregroundStyle(Color.appTextDim)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.sm)
    }

    private var groupedQuests: [(String, [Quest])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var sections: [String: [Quest]] = [:]
        for quest in completedQuests {
            let date = quest.completedAt ?? quest.createdAt
            let day = calendar.startOfDay(for: date)
            let label: String
            if day == today {
                label = AppCopy.History.sectionToday
            } else if day == yesterday {
                label = AppCopy.History.sectionYesterday
            } else {
                label = date.formatted(date: .abbreviated, time: .omitted)
            }
            sections[label, default: []].append(quest)
        }

        // Sort sections newest first
        return sections
            .sorted { lhs, rhs in
                let lDate = lhs.value.compactMap(\.completedAt).max() ?? lhs.value.first?.createdAt ?? .distantPast
                let rDate = rhs.value.compactMap(\.completedAt).max() ?? rhs.value.first?.createdAt ?? .distantPast
                return lDate > rDate
            }
    }
}

private struct QuestHistoryRow: View {
    let quest: Quest

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Timeline dot
            VStack {
                Circle()
                    .fill(Color.appSage)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(width: 1)
            }
            .frame(width: 8)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(quest.actionStep)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(3)

                if let reflection = quest.reflection, !reflection.isEmpty {
                    Text(reflection)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)
                        .italic()
                        .lineLimit(2)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
    }
}
