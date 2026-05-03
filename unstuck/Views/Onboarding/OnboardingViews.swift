import SwiftUI

// MARK: - Welcome Screen
// First screen new users see. Three lines of copy that fade up one by one.

struct WelcomeView: View {
    var onContinue: () -> Void

    @State private var step = 0

    private let lines = [
        AppCopy.Welcome.line1,
        AppCopy.Welcome.line2,
        AppCopy.Welcome.line3,
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Copy lines
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.appTitle)
                            .foregroundStyle(Color.appTextPrimary)
                            .lineSpacing(6)
                            .fadeUp(appear: step > index, delay: 0)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // CTA
                Button(action: onContinue) {
                    Text(AppCopy.Welcome.cta)
                        .font(.appCTA)
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appAmber)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
                .fadeUp(appear: step > 3, delay: 0)
            }
        }
        .onAppear { animateLines() }
    }

    private func animateLines() {
        for i in 1...4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                withAnimation { step = i }
            }
        }
    }
}

// MARK: - Onboarding: Name Input

struct OnboardingNameView: View {
    @Binding var name: String
    var onContinue: () -> Void

    @State private var appeared = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text(AppCopy.Onboarding.namePrompt)
                    .font(.appHeadline)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .fadeUp(appear: appeared, delay: 0)

                TextField(AppCopy.Onboarding.namePlaceholder, text: $name)
                    .font(.appTitle)
                    .foregroundStyle(Color.appTextPrimary)
                    .accentColor(Color.appAmber)
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .fadeUp(appear: appeared, delay: 0.1)

                Spacer()

                AppPrimaryButton(
                    title: AppCopy.Onboarding.continueButton,
                    isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    onContinue()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
                .fadeUp(appear: appeared, delay: 0.2)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focused = true
            }
        }
    }
}

// MARK: - Onboarding: Category Picker

struct OnboardingCategoryView: View {
    @Binding var selected: [QuestCategory]
    var onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Text(AppCopy.Onboarding.categoryPrompt)
                    .font(.appHeadline)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                    .fadeUp(appear: appeared, delay: 0)

                // Category pills
                FlowLayout(spacing: AppSpacing.sm) {
                    ForEach(QuestCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selected.contains(category)
                        ) {
                            withAnimation(AppAnimation.spring) {
                                if selected.contains(category) {
                                    selected.removeAll { $0 == category }
                                } else {
                                    selected.append(category)
                                }
                                Haptic.select()
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .fadeUp(appear: appeared, delay: 0.1)

                Text(AppCopy.Onboarding.categoryNote)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .fadeUp(appear: appeared, delay: 0.2)

                Spacer()

                AppPrimaryButton(
                    title: AppCopy.Onboarding.continueButton,
                    isEnabled: !selected.isEmpty
                ) {
                    onContinue()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
                .fadeUp(appear: appeared, delay: 0.3)
            }
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

private struct CategoryPill: View {
    let category: QuestCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Text(category.emoji)
                Text(category.displayName)
                    .font(.appLabel)
            }
            .foregroundStyle(isSelected ? Color.appBackground : Color.appTextSecondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? Color.appAmber : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.pill)
                    .strokeBorder(
                        isSelected ? Color.clear : Color.appDivider,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding: Energy Level

struct OnboardingEnergyView: View {
    @Binding var energy: EnergyLevel
    var onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Spacer()

                Text(AppCopy.Onboarding.energyPrompt)
                    .font(.appHeadline)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                    .fadeUp(appear: appeared, delay: 0)

                VStack(spacing: AppSpacing.md) {
                    ForEach(Array(EnergyLevel.allCases.enumerated()), id: \.element) { index, level in
                        EnergyOptionRow(
                            level: level,
                            isSelected: energy == level
                        ) {
                            withAnimation(AppAnimation.spring) {
                                energy = level
                                Haptic.select()
                            }
                        }
                        .fadeUp(appear: appeared, delay: Double(index + 1) * 0.08)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()

                AppPrimaryButton(
                    title: AppCopy.Onboarding.finishButton,
                    isEnabled: true
                ) {
                    onContinue()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
                .fadeUp(appear: appeared, delay: 0.4)
            }
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

private struct EnergyOptionRow: View {
    let level: EnergyLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Text(level.icon)
                    .font(.system(size: 28))

                Text(level.displayName)
                    .font(.appBodyLarge)
                    .foregroundStyle(isSelected ? Color.appTextPrimary : Color.appTextSecondary)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(Color.appAmber)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(AppSpacing.md)
            .background(isSelected ? Color.appSurface : Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(
                        isSelected ? Color.appAmber.opacity(0.5) : Color.appDivider,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding Coordinator

struct OnboardingFlow: View {
    var onComplete: (UserProfile) -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var name: String = ""
    @State private var categories: [QuestCategory] = []
    @State private var energy: EnergyLevel = .medium

    enum OnboardingStep {
        case welcome, name, categories, energy
    }

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                WelcomeView { advance() }
                    .transition(.opacity)
            case .name:
                OnboardingNameView(name: $name) { advance() }
                    .transition(.opacity)
            case .categories:
                OnboardingCategoryView(selected: $categories) { advance() }
                    .transition(.opacity)
            case .energy:
                OnboardingEnergyView(energy: $energy) {
                    let profile = UserProfile(
                        name: name.trimmingCharacters(in: .whitespaces),
                        energyLevel: energy,
                        selectedCategories: categories,
                        hasCompletedOnboarding: true
                    )
                    onComplete(profile)
                }
                .transition(.opacity)
            }
        }
        .animation(AppAnimation.fadeIn, value: step)
    }

    private func advance() {
        switch step {
        case .welcome:    step = .name
        case .name:       step = .categories
        case .categories: step = .energy
        case .energy:     break
        }
    }
}
