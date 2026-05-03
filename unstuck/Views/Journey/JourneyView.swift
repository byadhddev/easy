import SwiftUI
import SwiftData

// MARK: - Journey View
// Replaces the flat history log. Shows where your energy has gone,
// the steps you've taken, and the things you set aside — always retrievable.

struct JourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Quest.createdAt, order: .reverse) private var allQuests: [Quest]

    var onReactivate: ((Quest) -> Void)?

    private var completedQuests: [Quest] {
        allQuests.filter { $0.status == .completed }
    }

    private var setAsideQuests: [Quest] {
        allQuests.filter { $0.status == .set_aside }
    }

    // MARK: - Momentum

    private var momentumText: String {
        let count = completedQuests.count
        guard count > 0 else { return AppCopy.Journey.momentumNone }
        let focus = topCategory?.displayName ?? "many things"
        return AppCopy.Journey.momentum(count: count, focus: focus)
    }

    private var topCategory: QuestCategory? {
        let counts = QuestCategory.allCases.map { cat in
            (cat, completedQuests.filter { $0.category == cat }.count)
        }
        return counts.max(by: { $0.1 < $1.1 })?.0
    }

    // MARK: - Category distribution

    private func count(for category: QuestCategory) -> Int {
        completedQuests.filter { $0.category == category }.count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if allQuests.filter({ $0.status == .completed || $0.status == .set_aside }).isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Momentum sentence
                            momentumSection
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.top, AppSpacing.lg)

                            // Category distribution
                            if !completedQuests.isEmpty {
                                categorySection
                                    .padding(.top, AppSpacing.xl)
                            }

                            // Timeline of completed steps
                            if !completedQuests.isEmpty {
                                timelineSection
                                    .padding(.top, AppSpacing.xl)
                            }

                            // Things set aside
                            if !setAsideQuests.isEmpty {
                                setAsideSection
                                    .padding(.top, AppSpacing.xl)
                            }

                            Spacer().frame(height: AppSpacing.xxxl)
                        }
                    }
                }
            }
            .navigationTitle(AppCopy.Journey.title)
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

    // MARK: - Sections

    private var momentumSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(momentumText)
                .font(.appHeadline)
                .foregroundStyle(Color.appTextPrimary)
                .lineSpacing(5)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(AppCopy.Journey.categoryHeader.uppercased())
                .font(.appCaption)
                .foregroundStyle(Color.appTextDim)
                .tracking(1.2)
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                ForEach(QuestCategory.allCases, id: \.self) { cat in
                    let n = count(for: cat)
                    if n > 0 {
                        CategoryBar(
                            category: cat,
                            count: n,
                            total: completedQuests.count
                        )
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(AppCopy.Journey.timelineHeader.uppercased())
                .font(.appCaption)
                .foregroundStyle(Color.appTextDim)
                .tracking(1.2)
                .padding(.horizontal, AppSpacing.lg)

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(completedQuests) { quest in
                    TimelineRow(quest: quest)
                        .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }

    private var setAsideSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(AppCopy.Journey.setAsideHeader.uppercased())
                .font(.appCaption)
                .foregroundStyle(Color.appTextDim)
                .tracking(1.2)
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                ForEach(setAsideQuests) { quest in
                    SetAsideCard(quest: quest) {
                        onReactivate?(quest)
                        dismiss()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }

    private var emptyState: some View {
        Text(AppCopy.Journey.empty)
            .font(.appBody)
            .foregroundStyle(Color.appTextDim)
            .multilineTextAlignment(.center)
            .padding(AppSpacing.xl)
    }
}

// MARK: - Category Bar

private struct CategoryBar: View {
    let category: QuestCategory
    let count: Int
    let total: Int

    private var fraction: CGFloat { CGFloat(count) / CGFloat(max(total, 1)) }

    private var accentColor: Color {
        switch category {
        case .health:       return .appSage
        case .conversation: return .appRose
        case .work:         return .appAmber
        case .home:         return .appAmberDim
        case .unclear:      return .appTextDim
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Category label
            HStack(spacing: AppSpacing.xs) {
                Text(category.emoji)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(width: 110, alignment: .leading)

            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.appDivider)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(AppAnimation.spring, value: fraction)
                }
            }
            .frame(height: 6)

            // Count
            Text("\(count)")
                .font(.appCaption)
                .foregroundStyle(Color.appTextDim)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

// MARK: - Timeline Row

private struct TimelineRow: View {
    let quest: Quest

    private var categoryColor: Color {
        switch quest.category {
        case .health:       return .appSage
        case .conversation: return .appRose
        case .work:         return .appAmber
        case .home:         return .appAmberDim
        case .unclear:      return .appTextDim
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Timeline node
            VStack(spacing: 0) {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(quest.stepTitle)
                        .font(.appLabel)
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                    if let date = quest.completedAt {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextDim)
                    }
                }

                Text(quest.actionStep)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)

                if let reflection = quest.reflection, !reflection.isEmpty {
                    Text(""\(reflection)"")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)
                        .italic()
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
    }
}

// MARK: - Set Aside Card

private struct SetAsideCard: View {
    let quest: Quest
    let onReactivate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(quest.stepTitle)
                .font(.appLabel)
                .foregroundStyle(Color.appTextSecondary)

            Text(quest.actionStep)
                .font(.appCaption)
                .foregroundStyle(Color.appTextDim)
                .lineLimit(2)

            Button(AppCopy.Journey.reactivateCTA) {
                Haptic.commit()
                onReactivate()
            }
            .font(.appLabel)
            .foregroundStyle(Color.appAmber)
            .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(Color.appDivider, lineWidth: 1)
        )
    }
}
