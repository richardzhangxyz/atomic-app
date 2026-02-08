//
//  AppTheme.swift
//  AtomicApp
//
//  Design system for refined clinical calm aesthetic
//  Premium meditation app meets financial dashboard
//

import SwiftUI

// MARK: - App Theme

struct AppTheme {
    // MARK: - Colors
    
    struct Colors {
        // MARK: - Dynamic Colors (adapt to color scheme)
        
        /// Background - Deep charcoal (dark) / Warm off-white (light)
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#0F1117") : Color(hex: "#F5F3F0")
        }
        
        /// Background alt - Slightly different tone for variety
        static func backgroundAlt(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#141820") : Color(hex: "#EFEDE9")
        }
        
        /// Surface cards - Elevated from background
        static func surface(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#1A1E2A") : Color(hex: "#FFFFFF")
        }
        
        /// Surface elevated - Higher elevation
        static func surfaceElevated(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#1F2433") : Color(hex: "#FAFAF9")
        }
        
        /// Primary text - High contrast
        static func textPrimary(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#E8E4DF") : Color(hex: "#1C1C1E")
        }
        
        /// Secondary text - Medium contrast
        static func textSecondary(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#7A7D85") : Color(hex: "#5A5D65")
        }
        
        /// Muted text - Low contrast
        static func textMuted(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#5A5D65") : Color(hex: "#8E9199")
        }
        
        /// Border color
        static func border(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.08)
        }
        
        /// Divider color
        static func divider(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.1)
        }
        
        // MARK: - Fixed Colors (same in both modes)
        
        /// Primary accent - Muted teal/sage (works in both modes)
        static let accent = Color(hex: "#5B9A8B")
        static let accentAlt = Color(hex: "#6B9E8D")
        
        /// Warning state - Muted amber
        static let warning = Color(hex: "#C4935A")
        
        /// Destructive action - Desaturated soft red
        static let destructive = Color(hex: "#9E5B5B")
        
        /// Success state - Same as accent
        static let success = Color(hex: "#5B9A8B")
        
        // MARK: - Legacy Static Colors (for backwards compatibility)
        // These will be deprecated - use dynamic versions above
        
        static let background = Color(hex: "#0F1117")
        static let backgroundAlt = Color(hex: "#141820")
        static let surface = Color(hex: "#1A1E2A")
        static let surfaceElevated = Color(hex: "#1F2433")
        static let textPrimary = Color(hex: "#E8E4DF")
        static let textSecondary = Color(hex: "#7A7D85")
        static let textMuted = Color(hex: "#5A5D65")
        static let border = Color.white.opacity(0.06)
        static let divider = Color.white.opacity(0.08)
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Font weights
        static let light: Font.Weight = .light
        static let regular: Font.Weight = .regular
        static let medium: Font.Weight = .medium
        static let semibold: Font.Weight = .semibold
        static let bold: Font.Weight = .bold
        
        // Heading sizes
        static func largeTitle(weight: Font.Weight = .semibold) -> Font {
            .system(size: 26, weight: weight, design: .rounded)
        }
        
        static func title(weight: Font.Weight = .semibold) -> Font {
            .system(size: 22, weight: weight, design: .rounded)
        }
        
        static func headline(weight: Font.Weight = .medium) -> Font {
            .system(size: 16, weight: weight, design: .rounded)
        }
        
        static func body(weight: Font.Weight = .regular) -> Font {
            .system(size: 15, weight: weight, design: .rounded)
        }
        
        static func caption(weight: Font.Weight = .regular) -> Font {
            .system(size: 13, weight: weight, design: .rounded)
        }
        
        static func label(weight: Font.Weight = .semibold) -> Font {
            .system(size: 12, weight: weight, design: .rounded)
        }
        
        // Uppercase label with letter spacing
        static func uppercaseLabel() -> Font {
            .system(size: 11, weight: .semibold, design: .rounded)
        }
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        // Card padding
        static let cardPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 12
        
        // Section spacing
        static let sectionSpacing: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 14
        static let xl: CGFloat = 16
        static let button: CGFloat = 12
        static let card: CGFloat = 14
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        static func card() -> some View {
            EmptyView()
                .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
        }
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - View Modifiers

extension View {
    /// Apply card styling with theme
    func themeCard(colorScheme: ColorScheme? = nil) -> some View {
        ThemeCardModifier(colorScheme: colorScheme).apply(to: self)
    }
    
    /// Apply elevated card styling
    func themeCardElevated(colorScheme: ColorScheme? = nil) -> some View {
        ThemeCardElevatedModifier(colorScheme: colorScheme).apply(to: self)
    }
    
    /// Apply primary button styling
    func themePrimaryButton(isEnabled: Bool = true, colorScheme: ColorScheme? = nil) -> some View {
        ThemePrimaryButtonModifier(isEnabled: isEnabled, colorScheme: colorScheme).apply(to: self)
    }
    
    /// Apply outline button styling
    func themeOutlineButton(color: Color = AppTheme.Colors.destructive) -> some View {
        self
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(color, lineWidth: 1.5)
            )
    }
    
    /// Apply secondary button styling
    func themeSecondaryButton(colorScheme: ColorScheme? = nil) -> some View {
        ThemeSecondaryButtonModifier(colorScheme: colorScheme).apply(to: self)
    }
    
    /// Apply uppercase label styling with letter spacing
    func themeUppercaseLabel(colorScheme: ColorScheme? = nil) -> some View {
        ThemeUppercaseLabelModifier(colorScheme: colorScheme).apply(to: self)
    }
}

// MARK: - View Modifier Implementations

private struct ThemeCardModifier {
    let colorScheme: ColorScheme?
    @Environment(\.colorScheme) private var envColorScheme
    
    func apply<V: View>(to view: V) -> some View {
        let scheme = colorScheme ?? envColorScheme
        return view
            .background(AppTheme.Colors.surface(for: scheme))
            .cornerRadius(AppTheme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(AppTheme.Colors.border(for: scheme), lineWidth: 1)
            )
    }
}

private struct ThemeCardElevatedModifier {
    let colorScheme: ColorScheme?
    @Environment(\.colorScheme) private var envColorScheme
    
    func apply<V: View>(to view: V) -> some View {
        let scheme = colorScheme ?? envColorScheme
        return view
            .background(AppTheme.Colors.surfaceElevated(for: scheme))
            .cornerRadius(AppTheme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(AppTheme.Colors.border(for: scheme), lineWidth: 1)
            )
    }
}

private struct ThemePrimaryButtonModifier {
    let isEnabled: Bool
    let colorScheme: ColorScheme?
    @Environment(\.colorScheme) private var envColorScheme
    
    func apply<V: View>(to view: V) -> some View {
        let scheme = colorScheme ?? envColorScheme
        return view
            .foregroundColor(isEnabled ? .white : AppTheme.Colors.textMuted(for: scheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(isEnabled ? AppTheme.Colors.accent : AppTheme.Colors.surface(for: scheme))
            )
    }
}

private struct ThemeSecondaryButtonModifier {
    let colorScheme: ColorScheme?
    @Environment(\.colorScheme) private var envColorScheme
    
    func apply<V: View>(to view: V) -> some View {
        let scheme = colorScheme ?? envColorScheme
        return view
            .foregroundColor(AppTheme.Colors.textPrimary(for: scheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(AppTheme.Colors.surface(for: scheme))
            )
    }
}

private struct ThemeUppercaseLabelModifier {
    let colorScheme: ColorScheme?
    @Environment(\.colorScheme) private var envColorScheme
    
    func apply<V: View>(to view: V) -> some View {
        let scheme = colorScheme ?? envColorScheme
        return view
            .font(AppTheme.Typography.uppercaseLabel())
            .foregroundColor(AppTheme.Colors.textMuted(for: scheme))
            .kerning(1.2)
            .textCase(.uppercase)
    }
}

// MARK: - Reusable Components

struct ThemeStatusIndicator: View {
    let isActive: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? AppTheme.Colors.accent : AppTheme.Colors.textMuted(for: colorScheme))
                .frame(width: 8, height: 8)
            
            Text(isActive ? "Active" : "Inactive")
                .font(AppTheme.Typography.caption(weight: .medium))
                .foregroundColor(isActive ? AppTheme.Colors.accent : AppTheme.Colors.textMuted(for: colorScheme))
        }
    }
}

struct ThemeProgressBar: View {
    let progress: Double // 0.0 to 1.0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.surface(for: colorScheme))
                    .frame(height: 4)
                
                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.accent)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}

struct ThemeDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(AppTheme.Colors.divider(for: colorScheme))
            .frame(height: 1)
    }
}
