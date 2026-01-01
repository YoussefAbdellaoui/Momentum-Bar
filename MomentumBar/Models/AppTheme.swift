//
//  AppTheme.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

// MARK: - App Theme
struct AppTheme: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var accentColorHex: String
    var daytimeColorHex: String
    var nighttimeColorHex: String
    var backgroundStyle: BackgroundStyle
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        accentColorHex: String = "#007AFF",
        daytimeColorHex: String = "#FFD60A",
        nighttimeColorHex: String = "#5E5CE6",
        backgroundStyle: BackgroundStyle = .system,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.accentColorHex = accentColorHex
        self.daytimeColorHex = daytimeColorHex
        self.nighttimeColorHex = nighttimeColorHex
        self.backgroundStyle = backgroundStyle
        self.isBuiltIn = isBuiltIn
    }

    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }

    var daytimeColor: Color {
        Color(hex: daytimeColorHex) ?? .yellow
    }

    var nighttimeColor: Color {
        Color(hex: nighttimeColorHex) ?? .indigo
    }
}

// MARK: - Background Style
enum BackgroundStyle: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case vibrant = "vibrant"

    var description: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .vibrant: return "Vibrant"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        case .vibrant: return nil
        }
    }
}

// MARK: - Built-in Themes
extension AppTheme {
    static let defaultTheme = AppTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Default",
        accentColorHex: "#007AFF",
        daytimeColorHex: "#FFD60A",
        nighttimeColorHex: "#5E5CE6",
        backgroundStyle: .system,
        isBuiltIn: true
    )

    static let ocean = AppTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Ocean",
        accentColorHex: "#0A84FF",
        daytimeColorHex: "#64D2FF",
        nighttimeColorHex: "#0A84FF",
        backgroundStyle: .system,
        isBuiltIn: true
    )

    static let sunset = AppTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Sunset",
        accentColorHex: "#FF9F0A",
        daytimeColorHex: "#FFD60A",
        nighttimeColorHex: "#FF453A",
        backgroundStyle: .system,
        isBuiltIn: true
    )

    static let forest = AppTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Forest",
        accentColorHex: "#30D158",
        daytimeColorHex: "#32D74B",
        nighttimeColorHex: "#0A4A1F",
        backgroundStyle: .system,
        isBuiltIn: true
    )

    static let midnight = AppTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "Midnight",
        accentColorHex: "#BF5AF2",
        daytimeColorHex: "#FFD60A",
        nighttimeColorHex: "#5E5CE6",
        backgroundStyle: .dark,
        isBuiltIn: true
    )

    static let monochrome = AppTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "Monochrome",
        accentColorHex: "#8E8E93",
        daytimeColorHex: "#AEAEB2",
        nighttimeColorHex: "#48484A",
        backgroundStyle: .system,
        isBuiltIn: true
    )

    static let builtInThemes: [AppTheme] = [
        .defaultTheme,
        .ocean,
        .sunset,
        .forest,
        .midnight,
        .monochrome
    ]
}

// MARK: - Theme Manager
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var currentTheme: AppTheme = .defaultTheme
    var customThemes: [AppTheme] = []

    var allThemes: [AppTheme] {
        AppTheme.builtInThemes + customThemes
    }

    private init() {
        loadThemes()
    }

    func loadThemes() {
        // Load current theme ID from preferences
        let preferences = StorageService.shared.loadPreferences()
        if let themeID = preferences.selectedThemeID {
            currentTheme = allThemes.first { $0.id == themeID } ?? .defaultTheme
        }

        // Load custom themes
        if let data = UserDefaults.standard.data(forKey: "com.momentumbar.customThemes"),
           let themes = try? JSONDecoder().decode([AppTheme].self, from: data) {
            customThemes = themes
        }
    }

    func saveThemes() {
        if let data = try? JSONEncoder().encode(customThemes) {
            UserDefaults.standard.set(data, forKey: "com.momentumbar.customThemes")
        }
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        var preferences = StorageService.shared.loadPreferences()
        preferences.selectedThemeID = theme.id
        StorageService.shared.savePreferences(preferences)
    }

    func addCustomTheme(_ theme: AppTheme) {
        var newTheme = theme
        newTheme.isBuiltIn = false
        customThemes.append(newTheme)
        saveThemes()
    }

    func deleteCustomTheme(_ theme: AppTheme) {
        customThemes.removeAll { $0.id == theme.id }
        saveThemes()

        // Reset to default if deleted theme was current
        if currentTheme.id == theme.id {
            setTheme(.defaultTheme)
        }
    }

    func updateCustomTheme(_ theme: AppTheme) {
        if let index = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[index] = theme
            saveThemes()

            if currentTheme.id == theme.id {
                currentTheme = theme
            }
        }
    }
}
