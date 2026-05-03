import SwiftUI

// MARK: - Breathing Orb
// Used during AI processing and the check-in screen.
// Slow amber pulse — feels alive, not mechanical.

struct BreathingOrbView: View {
    var size: CGFloat = 120
    var color: Color = .appAmber

    @State private var isPulsing = false
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(glowOpacity))
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: 24)
                .scaleEffect(isPulsing ? 1.12 : 0.95)
                .animation(AppAnimation.breathe, value: isPulsing)

            // Mid ring
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(isPulsing ? 1.08 : 0.98)
                .animation(
                    AppAnimation.breathe.delay(0.15),
                    value: isPulsing
                )

            // Core orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color, color.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(isPulsing ? 1.05 : 0.97)
                .animation(
                    AppAnimation.breathe.delay(0.05),
                    value: isPulsing
                )
        }
        .onAppear {
            isPulsing = true
            withAnimation(AppAnimation.breathe) {
                glowOpacity = 0.5
            }
        }
    }
}

// MARK: - Bloom Animation
// Plays on quest completion — sage green wash expanding from center.

struct BloomView: View {
    var isPlaying: Bool
    var onComplete: (() -> Void)?

    @State private var scale: CGFloat = 0.01
    @State private var opacity: Double = 0.7

    var body: some View {
        GeometryReader { geo in
            let maxDimension = max(geo.size.width, geo.size.height) * 2.5

            ZStack {
                // Primary bloom
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appSage.opacity(0.6),
                                Color.appSage.opacity(0.2),
                                Color.appSage.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: maxDimension / 2
                        )
                    )
                    .frame(width: maxDimension, height: maxDimension)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Secondary ripple
                Circle()
                    .strokeBorder(Color.appSage.opacity(0.3), lineWidth: 1.5)
                    .frame(width: maxDimension * 0.6, height: maxDimension * 0.6)
                    .scaleEffect(scale * 1.15)
                    .opacity(opacity * 0.6)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: isPlaying) { _, playing in
            guard playing else { return }
            withAnimation(AppAnimation.bloom) {
                scale = 1.0
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                onComplete?()
                scale = 0.01
                opacity = 0.7
            }
        }
    }
}

// MARK: - Preview

#Preview("Breathing Orb") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: AppSpacing.xl) {
            BreathingOrbView(size: 140)
            Text(AppCopy.CheckIn.processingLabel)
                .font(.appBody)
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}

#Preview("Bloom Animation") {
    BloomPreviewWrapper()
}

private struct BloomPreviewWrapper: View {
    @State private var play = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            BloomView(isPlaying: play)
            Button("Play Bloom") { play.toggle() }
                .font(.appCTA)
                .foregroundStyle(Color.appAmber)
        }
    }
}
