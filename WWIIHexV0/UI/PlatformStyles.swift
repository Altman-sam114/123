import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum PlatformStyles {
    static var systemBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    static var secondarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    static var tertiarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(uiColor: .tertiarySystemBackground)
        #endif
    }

    static var panelStroke: Color {
        .secondary.opacity(0.28)
    }

    static var selectionTint: Color {
        .yellow.opacity(0.18)
    }
}

enum MingDesignTokens {
    static let cornerRadius: CGFloat = 8
    static let panelPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 12
    static let compactSpacing: CGFloat = 8
    static let minimumTapSize: CGFloat = 44

    static var cinnabar: Color {
        Color(red: 0.62, green: 0.13, blue: 0.12)
    }

    static var imperialGold: Color {
        Color(red: 0.82, green: 0.58, blue: 0.18)
    }

    static var ink: Color {
        Color(red: 0.12, green: 0.13, blue: 0.13)
    }

    static var jade: Color {
        Color(red: 0.14, green: 0.44, blue: 0.32)
    }

    static var porcelainBlue: Color {
        Color(red: 0.18, green: 0.34, blue: 0.56)
    }

    static var panelBackground: Color {
        PlatformStyles.systemBackground
    }

    static var sectionBackground: Color {
        PlatformStyles.tertiarySystemBackground
    }

    static var subtleSeal: Color {
        cinnabar.opacity(0.14)
    }

    static var courtStroke: Color {
        imperialGold.opacity(0.46)
    }
}
