import SwiftUI

// MARK: - Quest View
// The comfort paragraph IS the screen. The action step is secondary.
// No "quest" framing. This is one friend talking to another.

struct QuestView: View {
    let quest: Quest
    var onAccept: () -> Void       // "Keep this with me"
    var onSetAside: () -> Void     // "Set this aside" — NOT destructive

    @State private var appeared = false
    @State private var comfortScale: CGFloat = 0.97

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: AppSpacing.xxl)

                    // Small category label — quiet, not a title
                    Text(AppCopy.Quest.comfortLabel.uppercased())
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)
                        .tracking(1.5)
                        .fadeUp(appear: appeared, delay: 0)

                    Spacer().frame(height: AppSpacing.lg)

                    // Comfort paragraph — the emotional center
                    // Larger, warmer font — this is what they needed to hear
                    Text(quest.comfortParagraph)
                        .font(.appTitle)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineSpacing(10)
                        .scaleEffect(comfortScale, anchor: .topLeading)
                        .fadeUp(appear: appeared, delay: 0.1)

                    Spacer().frame(height: AppSpacing.xxl)

                    // Quiet divider + "one small step" label
                    AppDivider()
                        .fadeUp(appear: appeared, delay: 0.25)

                    Spacer().frame(height: AppSpacing.lg)

                    Text(AppCopy.Quest.stepLabel.uppercased())
                        .font(.appCaption)
                        .foregroundStyle(Color.appAmber.opacity(0.7))
                        .tracking(1.5)
                        .fadeUp(appear: appeared, delay: 0.3)

                    Spacer().frame(height: AppSpacing.md)

                    // The action step — clear and specific, but not dominant
                    Text(quest.actionStep)
                        .font(.appHeadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineSpacing(6)
                        .fadeUp(appear: appeared, delay: 0.35)

                    Spacer().frame(height: AppSpacing.xxxl)

                    // Accept — warm, not a commitment button
                    AppPrimaryButton(title: AppCopy.Quest.primaryCTA) {
                        Haptic.commit()
                        onAccept()
                    }
                    .fadeUp(appear: appeared, delay: 0.45)

                    Spacer().frame(height: AppSpacing.md)

                    // Set aside — quiet, never a red/destructive button
                    Button(AppCopy.Quest.setAsideCTA) {
                        Haptic.gentle()
                        onSetAside()
                    }
                    .font(.appLabel)
                    .foregroundStyle(Color.appTextDim)
                    .frame(maxWidth: .infinity)
                    .fadeUp(appear: appeared, delay: 0.5)

                    Spacer().frame(height: AppSpacing.xxxl)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            // Subtle breathing scale on comfort paragraph
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1)) {
                comfortScale = 1.0
            }
        }
        .dynamicTypeSize(.small ... .accessibility2)
    }
}

// MARK: - Send-off View
// Shown immediately after "Keep this with me." No bloom. No celebration.
// Just: "I'm holding this with you. Go at your pace."
// The quest is accepted. The reflection comes later.

struct SendOffView: View {
    let quest: Quest
    var profileName: String
    var onDismiss: () -> Void   // returns to home

    @State private var appeared = false
    @State private var particles = ThoughtParticle.generate(count: 20)

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            // Particles settle fully — representing the thing being held
            ThoughtParticlesView(settleProgress: 0.85)
                .animation(.easeInOut(duration: 2.5), value: true)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: AppSpacing.lg) {
                    Text(AppCopy.SendOff.headline(name: profileName))
                        .font(.appTitle)
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .fadeUp(appear: appeared, delay: 0.2)

                    Text(AppCopy.SendOff.body)
                        .font(.appQuote)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, AppSpacing.xl)
                        .fadeUp(appear: appeared, delay: 0.4)

                    // Step reminder — small, quiet
                    Text(""\(quest.stepTitle)"")
                        .font(.appLabel)
                        .foregroundStyle(Color.appAmber.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, AppSpacing.sm)
                        .fadeUp(appear: appeared, delay: 0.55)
                }

                Spacer().frame(height: AppSpacing.xxxl)

                Text(AppCopy.SendOff.note)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .fadeUp(appear: appeared, delay: 0.65)

                Spacer().frame(height: AppSpacing.xl)

                AppPrimaryButton(title: AppCopy.SendOff.cta) {
                    Haptic.gentle()
                    onDismiss()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
                .fadeUp(appear: appeared, delay: 0.75)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            Haptic.questArrived()
        }
    }
}

// MARK: - Reflection View
// Shown when the user returns to the app with an accepted quest.
// Four honest options. No judgment for any of them.

struct ReflectionView: View {
    let quest: Quest
    var onResult: (ReflectionOutcome) -> Void

    @State private var appeared = false
    @State private var selectedOutcome: ReflectionOutcome?

    enum ReflectionOutcome {
        case didIt
        case tried
        case notYet      // keep as accepted
        case setAside    // move to set_aside
    }

    private struct Option {
        let outcome: ReflectionOutcome
        let title: String
        let subtext: String
        let color: Color
    }

    private let options: [Option] = [
        Option(outcome: .didIt,    title: AppCopy.Reflection.optionDid,      subtext: AppCopy.Reflection.didSubtext,      color: .appSage),
        Option(outcome: .tried,    title: AppCopy.Reflection.optionTried,    subtext: AppCopy.Reflection.triedSubtext,    color: .appAmber),
        Option(outcome: .notYet,   title: AppCopy.Reflection.optionNotYet,   subtext: AppCopy.Reflection.notYetSubtext,   color: .appAmberDim),
        Option(outcome: .setAside, title: AppCopy.Reflection.optionSetAside, subtext: AppCopy.Reflection.setAsideSubtext, color: .appRose),
    ]

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Reminder of what they accepted
                    Text(""\(quest.stepTitle)"")
                        .font(.appCaption)
                        .foregroundStyle(Color.appAmber.opacity(0.7))
                        .fadeUp(appear: appeared, delay: 0)

                    Text(AppCopy.Reflection.prompt)
                        .font(.appTitle)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineSpacing(6)
                        .fadeUp(appear: appeared, delay: 0.1)

                    Spacer().frame(height: AppSpacing.md)

                    // Option cards
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(options.enumerated()), id: \.offset) { idx, option in
                            ReflectionOptionCard(
                                option: option,
                                isSelected: selectedOutcome == nil ? false : selectedOutcome! == option.outcome
                            ) {
                                withAnimation(AppAnimation.spring) {
                                    selectedOutcome = option.outcome
                                    Haptic.select()
                                }
                                // Brief delay so selection animates before transitioning
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    onResult(option.outcome)
                                }
                            }
                            .fadeUp(appear: appeared, delay: Double(idx) * 0.08 + 0.2)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .dynamicTypeSize(.small ... .accessibility2)
    }
}

private struct ReflectionOptionCard: View {
    struct Option {
        let outcome: ReflectionView.ReflectionOutcome
        let title: String
        let subtext: String
        let color: Color
    }

    let option: Option
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(option.color)
                    .frame(width: 3)
                    .padding(.vertical, AppSpacing.xs)
                    .opacity(isSelected ? 1 : 0.4)

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.appBodyLarge)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Color.appTextPrimary : Color.appTextSecondary)

                    Text(option.subtext)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)
                }

                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected ? Color.appSurface : Color.appBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .strokeBorder(
                                isSelected ? option.color.opacity(0.4) : Color.appDivider,
                                lineWidth: 1
                            )
                    )
                    .shadow(color: isSelected ? option.color.opacity(0.15) : .clear, radius: 10)
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.spring, value: isSelected)
    }
}

// MARK: - Completion View
// Reached from ReflectionView when user confirms they did it (or tried).
// Now earned — not automatic.

struct CompletionView: View {
    let quest: Quest
    let headline: String          // varies: "You moved something." vs "You showed up."
    var onDone: (String?) -> Void

    @State private var appeared = false
    @State private var bloomPlaying = false
    @State private var showReflection = false
    @State private var contentAppeared = false
    @State private var reflection = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            BloomView(isPlaying: bloomPlaying) {
                withAnimation(AppAnimation.fadeInSlow) {
                    contentAppeared = true
                }
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: AppSpacing.lg) {
                    Text(headline)
                        .font(.appHero)
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(quest.stepTitle)
                        .font(.appBody)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)

                    Text(AppCopy.Completion.subheadline)
                        .font(.appQuote)
                        .foregroundStyle(Color.appSage)
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 16)

                Spacer().frame(height: AppSpacing.xxxl)

                if showReflection {
                    reflectionSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        Button(AppCopy.Completion.reflectionPrompt) {
                            withAnimation(AppAnimation.spring) { showReflection = true }
                        }
                        .font(.appLabel)
                        .foregroundStyle(Color.appTextDim)
                        .opacity(contentAppeared ? 1 : 0)

                        AppGhostButton(title: AppCopy.Completion.doneButton) {
                            Haptic.gentle()
                            onDone(nil)
                        }
                        .opacity(contentAppeared ? 1 : 0)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                Spacer()
            }
        }
        .onAppear {
            Haptic.complete()
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bloomPlaying = true }
        }
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            TextEditor(text: $reflection)
                .font(.appBody)
                .foregroundStyle(Color.appTextPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .frame(height: 120)
                .padding(AppSpacing.sm)
                .accentColor(Color.appAmber)
                .overlay(
                    Group {
                        if reflection.isEmpty {
                            Text("Write anything...")
                                .font(.appBody)
                                .foregroundStyle(Color.appTextDim)
                                .padding(AppSpacing.lg)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                )

            HStack {
                if reflection.isEmpty {
                    Button(AppCopy.Completion.reflectionSkip) { onDone(nil) }
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)
                }
                Spacer()
                AppPrimaryButton(title: AppCopy.Shared.done) {
                    onDone(reflection.isEmpty ? nil : reflection)
                }
                .frame(width: 120)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

