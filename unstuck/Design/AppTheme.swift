import SwiftUI

// MARK: - Color Tokens
extension Color {
    // Backgrounds
    static let appBackground     = Color(hex: "#1A1814") // Deep warm charcoal
    static let appSurface        = Color(hex: "#2A2520") // Elevated card surface
    static let appSurfaceRaised  = Color(hex: "#332E28") // Modal / sheet surface

    // Accents
    static let appAmber          = Color(hex: "#C8966A") // Primary accent — warmth
    static let appAmberDim       = Color(hex: "#8F6547") // Dimmed amber for secondary
    static let appSage           = Color(hex: "#7A9E7E")  // Completion / success
    static let appRose           = Color(hex: "#9A7B72")  // Muted secondary actions

    // Text
    static let appTextPrimary    = Color(hex: "#F0EBE3") // Off-white — readable
    static let appTextSecondary  = Color(hex: "#A09288") // Muted — hints, labels
    static let appTextDim        = Color(hex: "#6B5E56") // Dimmed — disabled states

    // Semantic
    static let appDivider        = Color(hex: "#3A332D")
    static let appOverlay        = Color.black.opacity(0.5)
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography Tokens
extension Font {
    // New York Serif — emotional weight, large statements
    // Uses .system(design: .serif) which resolves to New York on iOS 17+
    static let appHero      = Font.system(size: 34, weight: .semibold, design: .serif)
    static let appTitle     = Font.system(size: 28, weight: .regular,  design: .serif)
    static let appHeadline  = Font.system(size: 22, weight: .regular,  design: .serif)
    static let appQuote     = Font.system(size: 18, weight: .light,    design: .serif)

    // SF Pro Rounded — body, approachable
    static let appBody      = Font.system(.body, design: .rounded)
    static let appBodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let appLabel     = Font.system(size: 14, weight: .medium, design: .rounded)
    static let appCaption   = Font.system(size: 12, weight: .regular, design: .rounded)
    static let appCTA       = Font.system(size: 17, weight: .semibold, design: .rounded)
}

// MARK: - Spacing & Corner Tokens
enum AppSpacing {
    static let xs:    CGFloat = 4
    static let sm:    CGFloat = 8
    static let md:    CGFloat = 16
    static let lg:    CGFloat = 24
    static let xl:    CGFloat = 32
    static let xxl:   CGFloat = 48
    static let xxxl:  CGFloat = 64
}

enum AppRadius {
    static let sm:    CGFloat = 8
    static let md:    CGFloat = 16
    static let lg:    CGFloat = 24
    static let pill:  CGFloat = 999
}

// MARK: - Animation Tokens
enum AppAnimation {
    static let fadeIn       = Animation.easeOut(duration: 0.4)
    static let fadeInSlow   = Animation.easeOut(duration: 0.7)
    static let spring       = Animation.spring(response: 0.5, dampingFraction: 0.75)
    static let breathe      = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    static let bloom        = Animation.easeInOut(duration: 1.2)

    /// Stagger delay for onboarding elements
    static func stagger(_ index: Int) -> Animation {
        .easeOut(duration: 0.4).delay(Double(index) * 0.1)
    }
}

// MARK: - View Modifiers

struct FadeUpModifier: ViewModifier {
    let appear: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(delay), value: appear)
    }
}

extension View {
    /// Fades content up into position with optional stagger delay.
    func fadeUp(appear: Bool, delay: Double = 0) -> some View {
        modifier(FadeUpModifier(appear: appear, delay: delay))
    }
}
