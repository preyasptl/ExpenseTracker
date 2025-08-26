//
//  ThemeColors.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//

import SwiftUI

import SwiftUI

struct ThemeColors {
    static let primary = Color(red: 0.2, green: 0.6, blue: 0.86) // Beautiful blue
    static let secondary = Color(red: 0.95, green: 0.95, blue: 0.97) // Light gray
    static let accent = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
    
    // Cross-platform compatible colors
    #if os(iOS)
    static let background = Color(UIColor.systemBackground)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let text = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    #else
    static let background = Color(NSColor.controlBackgroundColor)
    static let cardBackground = Color(NSColor.controlColor)
    static let text = Color(NSColor.labelColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    #endif
    
    static let success = Color.green
    static let error = Color.red
    
    // Gradient backgrounds
    static let primaryGradient = LinearGradient(
        colors: [primary, primary.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackground.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
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
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        #if os(iOS)
        let uic = UIColor(self)
        #else
        let uic = NSColor(self)
        #endif
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
