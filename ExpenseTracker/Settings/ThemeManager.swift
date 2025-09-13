//
//  ThemeManager.swift
//  ExpenseTracker
//
//  Created by iMacPro on 11/09/25.
//


import SwiftUI

// MARK: - Theme Manager for App-wide Theme Handling
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
            applyTheme()
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.system.rawValue
        self.selectedTheme = AppTheme(rawValue: savedTheme) ?? .system
        applyTheme()
    }
    
    private func applyTheme() {
        DispatchQueue.main.async {
            #if os(iOS)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            
            for window in windowScene.windows {
                switch self.selectedTheme {
                case .light:
                    window.overrideUserInterfaceStyle = .light
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                case .system:
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
            #elseif os(macOS)
            switch self.selectedTheme {
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .system:
                NSApp.appearance = nil
            }
            #endif
        }
    }
}

// MARK: - App Theme Enum
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Always use light mode"
        case .dark: return "Always use dark mode"
        case .system: return "Follow system settings"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .light: return .orange
        case .dark: return .indigo
        case .system: return .blue
        }
    }
}

// MARK: - Theme Selection View
struct ThemeSelectionView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    ThemeOptionRow(
                        theme: theme,
                        isSelected: theme == themeManager.selectedTheme
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.selectedTheme = theme
                        }
                    }
                }
            } header: {
                Text("Choose how the app should appear")
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
            } footer: {
                Text("System theme automatically switches between light and dark mode based on your device settings.")
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
            }
            
            // Theme Preview Section
            Section("Preview") {
                ThemePreviewCard(selectedTheme: themeManager.selectedTheme)
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme icon
                ZStack {
                    Circle()
                        .fill(theme.previewColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: theme.icon)
                        .foregroundColor(theme.previewColor)
                        .font(.title3)
                }
                
                // Theme info
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ThemeColors.text)
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ThemeColors.primary)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    let selectedTheme: AppTheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ExpenseTracker")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(selectedTheme.displayName) Theme")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                Circle()
                    .fill(ThemeColors.primaryGradient)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }
            
            // Sample expense card
            HStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coffee & Breakfast")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Food • Today")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                Text("$12.50")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(ThemeColors.cardBackground)
            .cornerRadius(12)
            
            // Sample summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    Text("$1,234.56")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    Text("$5,678.90")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ThemeColors.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
