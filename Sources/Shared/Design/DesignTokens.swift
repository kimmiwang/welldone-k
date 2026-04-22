import SwiftUI

// MARK: - Design System Constants
/// 遵循 Apple HIG 的设计系统
enum DesignTokens {
    // MARK: Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let xxxl: CGFloat = 24
    }

    // MARK: Corner Radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
    }

    // MARK: Font
    enum Typography {
        static let caption2 = Font.system(size: 10, weight: .medium)
        static let caption = Font.system(size: 11, weight: .regular)
        static let footnote = Font.system(size: 12, weight: .regular)
        static let subheadline = Font.system(size: 13, weight: .medium)
        static let body = Font.system(size: 14, weight: .regular)
        static let headline = Font.system(size: 15, weight: .semibold)
        static let title3 = Font.system(size: 17, weight: .semibold)
        static let title2 = Font.system(size: 20, weight: .bold)
        static let title = Font.system(size: 24, weight: .bold)
    }

    // MARK: Shadow
    enum Shadow {
        static let sm = Color.black.opacity(0.06)
        static let md = Color.black.opacity(0.1)
        static let lg = Color.black.opacity(0.15)
    }

    // MARK: Animation
    enum Motion {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.35)
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
}
