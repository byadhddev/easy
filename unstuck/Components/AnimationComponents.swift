import SwiftUI

// MARK: - Thought Particles
// 28 small dim particles that float like unresolved thoughts.
// As `settleProgress` increases (0→1), they drift toward the bottom
// and fade — the visual metaphor: naming what's heavy dissolves it.
//
// Uses TimelineView + Canvas for smooth 60fps without UIKit.

struct ThoughtParticlesView: View {
    /// 0.0 = particles floating freely   1.0 = fully settled / faded
    var settleProgress: Double

    @State private var particles: [ThoughtParticle] = ThoughtParticle.generate()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                for p in particles {
                    // Natural drifting position
                    let nx = p.baseX * size.width
                        + sin(t * p.driftSpeedX + p.phase) * p.driftAmplitude
                    let ny = p.baseY * size.height
                        + cos(t * p.driftSpeedY + p.phase * 1.3) * p.driftAmplitude * 0.7

                    // Settle toward bottom-center
                    let sx = size.width * 0.5 + (nx - size.width * 0.5) * 0.3
                    let sy = size.height * 0.88

                    let x = nx + (sx - nx) * settleProgress
                    let y = ny + (sy - ny) * settleProgress

                    let opacity = p.baseOpacity * (1.0 - settleProgress * 0.95)
                    guard opacity > 0.01 else { continue }

                    let color = p.isAmber
                        ? Color.appAmber.opacity(opacity)
                        : Color.appTextPrimary.opacity(opacity * 0.55)

                    context.fill(
                        Circle().path(in: CGRect(
                            x: x - p.radius,
                            y: y - p.radius,
                            width: p.radius * 2,
                            height: p.radius * 2
                        )),
                        with: .color(color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ThoughtParticle {
    let baseX: Double
    let baseY: Double
    let radius: Double
    let baseOpacity: Double
    let driftSpeedX: Double
    let driftSpeedY: Double
    let driftAmplitude: Double
    let phase: Double
    let isAmber: Bool

    static func generate(count: Int = 28) -> [ThoughtParticle] {
        (0..<count).map { i in
            let isAmber = i % 5 == 0   // ~20% amber, rest dim white
            return ThoughtParticle(
                baseX:          Double.random(in: 0.05...0.95),
                baseY:          Double.random(in: 0.08...0.72),
                radius:         Double.random(in: 1.5...4.0),
                baseOpacity:    Double.random(in: 0.18...0.55),
                driftSpeedX:    Double.random(in: 0.12...0.35),
                driftSpeedY:    Double.random(in: 0.08...0.25),
                driftAmplitude: Double.random(in: 14...32),
                phase:          Double.random(in: 0...Double.pi * 2),
                isAmber:        isAmber
            )
        }
    }
}

// MARK: - Ripple Effect
// A single expanding ring that fades out — used for keystrokes and selection moments.

struct RippleRing: Identifiable {
    let id = UUID()
    var scale: CGFloat = 0.3
    var opacity: Double = 0.7
    let color: Color
}

// MARK: - Resonance Rings
// Two concentric rings that expand and fade when a card/choice is confirmed.
// Metaphor: like striking a tuning fork — "this resonates."

struct ResonanceRingsView: View {
    var isActive: Bool
    var color: Color = .appAmber

    @State private var rings: [RippleRing] = []

    var body: some View {
        ZStack {
            ForEach(rings) { ring in
                Circle()
                    .strokeBorder(ring.color.opacity(ring.opacity), lineWidth: 1.5)
                    .scaleEffect(ring.scale)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            guard active else { return }
            // Fire two rings with slight delay
            for delay in [0.0, 0.18] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    let ring = RippleRing(color: color)
                    rings.append(ring)
                    let idx = rings.count - 1
                    withAnimation(.easeOut(duration: 0.7)) {
                        rings[idx].scale = 1.8
                        rings[idx].opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        rings.removeAll { $0.id == ring.id }
                    }
                }
            }
        }
    }
}

// MARK: - Micro Burst
// 3 tiny dots that fly outward from a point and fade.
// Used on category pill selection — "exhaling" the acknowledged thing.

struct MicroBurstView: View {
    var isActive: Bool
    var color: Color = .appAmber

    @State private var particles: [BurstParticle] = []

    struct BurstParticle: Identifiable {
        let id = UUID()
        let angle: Double
        var distance: CGFloat = 0
        var opacity: Double = 0.85
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(color.opacity(p.opacity))
                    .frame(width: 5, height: 5)
                    .offset(
                        x: cos(p.angle) * p.distance,
                        y: sin(p.angle) * p.distance
                    )
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            guard active else { return }
            let angles = [Double.pi * 0.3, Double.pi * 1.0, Double.pi * 1.7]
            let newParticles = angles.map { BurstParticle(angle: $0) }
            particles = newParticles
            for i in particles.indices {
                withAnimation(.easeOut(duration: 0.5)) {
                    particles[i].distance = CGFloat.random(in: 22...38)
                    particles[i].opacity = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                particles.removeAll()
            }
        }
    }
}

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
