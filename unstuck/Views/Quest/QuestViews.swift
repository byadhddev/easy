import SwiftUI

// MARK: - Quest View
// The most important screen. Comfort paragraph + one bold step.
// No pressure. Two options: try it or not ready yet.

struct QuestView: View {
    let quest: Quest
    var onComplete: () -> Void
    var onSkip: () -> Void

    @State private var appeared = false
    @State private var showDismissConfirm = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // "your quest" label
                    Text(AppCopy.Quest.label)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)
                        .padding(.top, AppSpacing.xxl)
                        .fadeUp(appear: appeared, delay: 0)

                    Spacer().frame(height: AppSpacing.lg)

                    // Comfort paragraph — AI-written, serif
                    Text(quest.comfortParagraph)
                        .font(.appQuote)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineSpacing(8)
                        .fadeUp(appear: appeared, delay: 0.1)

                    Spacer().frame(height: AppSpacing.xl)
                    AppDivider()
                        .fadeUp(appear: appeared, delay: 0.2)
                    Spacer().frame(height: AppSpacing.xl)

                    // The one step — bold, clear
                    Text(quest.actionStep)
                        .font(.appHeadline)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineSpacing(6)
                        .fadeUp(appear: appeared, delay: 0.3)

                    Spacer().frame(height: AppSpacing.xxxl)

                    // Action buttons
                    VStack(spacing: AppSpacing.sm) {
                        AppPrimaryButton(title: AppCopy.Quest.primaryCTA) {
                            withAnimation(AppAnimation.spring) {
                                Haptic.commit()
                                onComplete()
                            }
                        }
                        .fadeUp(appear: appeared, delay: 0.4)

                        AppGhostButton(title: AppCopy.Quest.notReadyCTA) {
                            Haptic.gentle()
                            showDismissConfirm = true
                        }
                        .fadeUp(appear: appeared, delay: 0.45)
                    }

                    Spacer().frame(height: AppSpacing.xxxl)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .dynamicTypeSize(.small ... .accessibility2)
        .alert(AppCopy.Quest.dismissMessage, isPresented: $showDismissConfirm) {
            Button("Keep it", role: .cancel) { }
            Button("Let it go", role: .destructive) { onSkip() }
        }
    }
}

// MARK: - Completion View
// Sage bloom + "You did it." + optional reflection journal.

struct CompletionView: View {
    let quest: Quest
    var onDone: (String?) -> Void  // passes reflection text if entered

    @State private var appeared = false
    @State private var bloomPlaying = false
    @State private var showReflection = false
    @State private var reflection = ""
    @State private var contentAppeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Bloom animation layer
            BloomView(isPlaying: bloomPlaying) {
                withAnimation(AppAnimation.fadeInSlow) {
                    contentAppeared = true
                }
            }

            // Content
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: AppSpacing.lg) {
                    Text(AppCopy.Completion.headline)
                        .font(.appHero)
                        .foregroundStyle(Color.appTextPrimary)

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

                // Reflection prompt (slides up after content)
                if showReflection {
                    reflectionSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        Button(AppCopy.Completion.reflectionPrompt) {
                            withAnimation(AppAnimation.spring) {
                                showReflection = true
                            }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bloomPlaying = true
            }
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
                    Button(AppCopy.Completion.reflectionSkip) {
                        onDone(nil)
                    }
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
