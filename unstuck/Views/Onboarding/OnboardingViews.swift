import SwiftUI

// MARK: - Welcome Screen
// The screen opens with floating thought particles — unresolved, drifting.
// As each copy line appears, the particles settle and fade (being named dissolves them).
// By the CTA, the screen has cleared. Space has been made.

struct WelcomeView: View {
    var onContinue: () -> Void

    @State private var step = 0

    // settleProgress maps step → how dissolved the particles are
    private var settleProgress: Double {
        switch step {
        case 0:       return 0.0
        case 1:       return 0.25
        case 2:       return 0.55
        case 3, 4:    return 0.90
        default:      return 0.0
        }
    }

    private let lines = [
        AppCopy.Welcome.line1,
        AppCopy.Welcome.line2,
        AppCopy.Welcome.line3,
    ]

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            // Thought particles fill the full screen behind everything
            ThoughtParticlesView(settleProgress: settleProgress)
                .animation(.easeInOut(duration: 1.2), value: settleProgress)

            VStack(spacing: 0) {
                Spacer()

                // Copy lines — appear over the clearing field
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

                Button(action: { Haptic.commit(); onContinue() }) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.75) {
                withAnimation(AppAnimation.spring) { step = i }
            }
        }
    }
}

// MARK: - Onboarding: Name Input
// Each keystroke emits a brief ripple from the text.
// When ≥2 chars, a warm recognition glow pulses — "this space knows you."

struct OnboardingNameView: View {
    @Binding var name: String
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var glowActive = false
    @State private var rippleTrigger = false
    @State private var recognitionPulse = false
    @FocusState private var focused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                OnboardingProgressDots(total: 3, current: 0)
                    .padding(.top, AppSpacing.xl)
                    .fadeUp(appear: appeared, delay: 0)

                Spacer()

                VStack(spacing: AppSpacing.xl) {
                    Text(AppCopy.Onboarding.namePrompt)
                        .font(.appHeadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .fadeUp(appear: appeared, delay: 0)

                    ZStack(alignment: .bottom) {
                        // Recognition glow blooms under name
                        if glowActive {
                            Ellipse()
                                .fill(Color.appAmber.opacity(0.22))
                                .frame(height: 10)
                                .blur(radius: 18)
                                .offset(y: 14)
                                .scaleEffect(recognitionPulse ? 1.3 : 1.0)
                                .transition(.opacity.combined(with: .scale))
                        }

                        // Keystroke ripple ring
                        ResonanceRingsView(isActive: rippleTrigger, color: .appAmber)
                            .frame(width: 200, height: 200)

                        // Name text
                        TextField(AppCopy.Onboarding.namePlaceholder, text: $name)
                            .font(.appHero)
                            .foregroundStyle(Color.appTextPrimary)
                            .accentColor(Color.appAmber)
                            .multilineTextAlignment(.center)
                            .focused($focused)
                            .submitLabel(.done)
                            .onSubmit { if !trimmed.isEmpty { onContinue() } }

                        // Animated amber underline
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.appAmber)
                                .frame(
                                    width: trimmed.isEmpty ? 40 : min(CGFloat(trimmed.count) * 19, geo.size.width * 0.85),
                                    height: 2
                                )
                                .frame(maxWidth: .infinity, alignment: .center)
                                .animation(AppAnimation.spring, value: trimmed.count)
                        }
                        .frame(height: 2)
                        .offset(y: 8)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .onChange(of: trimmed) { old, new in
                        // Ripple on every new character
                        if new.count > old.count {
                            rippleTrigger.toggle()
                        }
                        withAnimation(AppAnimation.spring) {
                            glowActive = new.count >= 2
                        }
                        // Recognition pulse at exactly 2 chars
                        if new.count == 2 {
                            withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
                                recognitionPulse = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                recognitionPulse = false
                            }
                            Haptic.gentle()
                        }
                    }
                }

                Spacer()

                if !trimmed.isEmpty {
                    AppPrimaryButton(title: AppCopy.Onboarding.continueButton, isEnabled: true) {
                        onContinue()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: AppSpacing.xxxl)
            }
        }
        .animation(AppAnimation.spring, value: trimmed.isEmpty)
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
        }
    }
}

// MARK: - Onboarding: Category Picker
// Selecting a pill fires a micro-burst of 3 dots — like exhaling the acknowledged thing.

struct OnboardingCategoryView: View {
    @Binding var selected: [QuestCategory]
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var burstTriggers: [QuestCategory: Bool] = [:]

    private var countLabel: String {
        switch selected.count {
        case 0:  return " "
        case 1:  return "1 thing on your mind"
        default: return "\(selected.count) things on your mind"
        }
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                OnboardingProgressDots(total: 3, current: 1)
                    .padding(.top, AppSpacing.xl)
                    .fadeUp(appear: appeared, delay: 0)

                Spacer()

                VStack(spacing: AppSpacing.lg) {
                    Text(AppCopy.Onboarding.categoryPrompt)
                        .font(.appHeadline)
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                        .fadeUp(appear: appeared, delay: 0)

                    FlowLayout(spacing: AppSpacing.sm) {
                        ForEach(Array(QuestCategory.allCases.enumerated()), id: \.element) { idx, category in
                            ZStack {
                                CategoryPill(
                                    category: category,
                                    isSelected: selected.contains(category)
                                ) {
                                    let wasSelected = selected.contains(category)
                                    withAnimation(AppAnimation.spring) {
                                        if wasSelected {
                                            selected.removeAll { $0 == category }
                                        } else {
                                            selected.append(category)
                                            // Burst only on selection, not deselection
                                            burstTriggers[category, default: false].toggle()
                                        }
                                        Haptic.select()
                                    }
                                }

                                // Micro burst on selection
                                MicroBurstView(
                                    isActive: burstTriggers[category, default: false]
                                )
                            }
                            .fadeUp(appear: appeared, delay: Double(idx) * 0.06)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Text(countLabel)
                        .font(.appCaption)
                        .foregroundStyle(selected.isEmpty ? Color.appTextDim : Color.appAmber)
                        .animation(AppAnimation.fadeIn, value: selected.count)
                        .fadeUp(appear: appeared, delay: 0.3)

                    Text(AppCopy.Onboarding.categoryNote)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                        .fadeUp(appear: appeared, delay: 0.35)
                }

                Spacer()

                AppPrimaryButton(
                    title: AppCopy.Onboarding.continueButton,
                    isEnabled: !selected.isEmpty
                ) { onContinue() }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
                .fadeUp(appear: appeared, delay: 0.4)
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
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? Color.appAmber.opacity(0.45) : .clear,
                radius: 8, x: 0, y: 2
            )
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.spring, value: isSelected)
    }
}

// MARK: - Onboarding: Energy Level
// When a card is selected, resonance rings expand from it — like striking a tuning fork.

struct OnboardingEnergyView: View {
    @Binding var energy: EnergyLevel
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var resonanceTriggers: [EnergyLevel: Bool] = [:]

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                OnboardingProgressDots(total: 3, current: 2)
                    .padding(.top, AppSpacing.xl)
                    .fadeUp(appear: appeared, delay: 0)

                Spacer()

                VStack(spacing: AppSpacing.lg) {
                    Text(AppCopy.Onboarding.energyPrompt)
                        .font(.appHeadline)
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                        .fadeUp(appear: appeared, delay: 0)

                    VStack(spacing: AppSpacing.md) {
                        ForEach(Array(EnergyLevel.allCases.enumerated()), id: \.element) { index, level in
                            EnergyCard(
                                level: level,
                                isSelected: energy == level,
                                resonanceTrigger: resonanceTriggers[level, default: false]
                            ) {
                                withAnimation(AppAnimation.spring) {
                                    energy = level
                                    resonanceTriggers[level, default: false].toggle()
                                    Haptic.select()
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .fadeUp(appear: appeared, delay: Double(index) * 0.1 + 0.1)
                        }
                    }
                }

                Spacer()

                AppPrimaryButton(
                    title: AppCopy.Onboarding.finishButton,
                    isEnabled: true
                ) { onContinue() }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
                .fadeUp(appear: appeared, delay: 0.45)
            }
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

private struct EnergyCard: View {
    let level: EnergyLevel
    let isSelected: Bool
    let resonanceTrigger: Bool
    let action: () -> Void

    private var accentColor: Color {
        switch level {
        case .low:    return .appRose
        case .medium: return .appAmberDim
        case .okay:   return .appSage
        }
    }

    private var title: String {
        switch level {
        case .low:    return AppCopy.Onboarding.Energy.lowTitle
        case .medium: return AppCopy.Onboarding.Energy.mediumTitle
        case .okay:   return AppCopy.Onboarding.Energy.okayTitle
        }
    }

    private var description: String {
        switch level {
        case .low:    return AppCopy.Onboarding.Energy.lowDesc
        case .medium: return AppCopy.Onboarding.Energy.mediumDesc
        case .okay:   return AppCopy.Onboarding.Energy.okayDesc
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: 4)
                        .padding(.vertical, AppSpacing.sm)
                        .opacity(isSelected ? 1 : 0.4)

                    HStack(spacing: AppSpacing.md) {
                        Text(level.icon)
                            .font(.system(size: 36))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.appBodyLarge)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(isSelected ? Color.appTextPrimary : Color.appTextSecondary)

                            Text(description)
                                .font(.appCaption)
                                .foregroundStyle(Color.appTextDim)
                                .lineLimit(2)
                        }

                        Spacer()

                        if isSelected {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 10, height: 10)
                                .shadow(color: accentColor.opacity(0.6), radius: 6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(isSelected ? Color.appSurface : Color.appBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .strokeBorder(
                                    isSelected ? accentColor.opacity(0.5) : Color.appDivider,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isSelected ? accentColor.opacity(0.2) : .clear,
                            radius: 12, x: 0, y: 4
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .scaleEffect(isSelected ? 1.02 : 1.0)

                // Resonance rings emanate from the card on selection
                ResonanceRingsView(isActive: resonanceTrigger, color: accentColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.spring, value: isSelected)
    }
}

// MARK: - Onboarding Coordinator

struct OnboardingFlow: View {
    var onComplete: (UserProfile) -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var name: String = ""
    @State private var categories: [QuestCategory] = []
    @State private var energy: EnergyLevel = .medium

    enum OnboardingStep: Int {
        case welcome, name, categories, energy
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            switch step {
            case .welcome:
                WelcomeView { advance() }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .name:
                OnboardingNameView(name: $name) { advance() }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .categories:
                OnboardingCategoryView(selected: $categories) { advance() }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
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
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: step)
    }

    private func advance() {
        Haptic.commit()
        switch step {
        case .welcome:    step = .name
        case .name:       step = .categories
        case .categories: step = .energy
        case .energy:     break
        }
    }
}


