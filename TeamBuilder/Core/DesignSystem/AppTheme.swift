//
//  AppTheme.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI
import UIKit
import CoreText

enum AppTheme {
    static let halvarFontName = "HalvarBreitt2-XBd"
    static let rooftopRegularFontName = "T2Rooftop-Regular"
    static let rooftopMediumFontName = "T2Rooftop-Medium"

    static let background = dynamicColor(light: UIColor(red: 1, green: 1, blue: 1, alpha: 1.0),
                                         dark: UIColor(red: 0, green: 0, blue: 0, alpha: 1.0))
    static let surface = dynamicColor(light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                                      dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0))
    static let elevatedSurface = dynamicColor(light: UIColor(red: 0.92, green: 0.93, blue: 0.96, alpha: 1.0),
                                              dark: UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0))
    static let accent = Color(red: 1.0, green: 0.2039, blue: 0.5843)
    static let primaryButtonBackground = Color(red: 167.0 / 255.0, green: 252.0 / 255.0, blue: 0.0)

    static let secondaryAccent = dynamicColor(light: UIColor(red: 0.19, green: 0.58, blue: 0.96, alpha: 1.0),
                                              dark: UIColor(red: 0.53, green: 0.84, blue: 0.99, alpha: 1.0))
    static let textPrimary = dynamicColor(light: UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0),
                                          dark: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    static let textSecondary = dynamicColor(light: UIColor(red: 0.38, green: 0.40, blue: 0.46, alpha: 1.0),
                                            dark: UIColor(red: 0.70, green: 0.70, blue: 0.74, alpha: 1.0))
    static let border = dynamicColor(light: UIColor(red: 0.86, green: 0.88, blue: 0.92, alpha: 1.0),
                                     dark: UIColor(red: 0.23, green: 0.23, blue: 0.27, alpha: 1.0))
    static let success = dynamicColor(light: UIColor(red: 0.11, green: 0.60, blue: 0.34, alpha: 1.0),
                                      dark: UIColor(red: 0.39, green: 0.85, blue: 0.56, alpha: 1.0))
    static let danger = dynamicColor(light: UIColor(red: 0.83, green: 0.22, blue: 0.28, alpha: 1.0),
                                     dark: UIColor(red: 1.0, green: 0.42, blue: 0.47, alpha: 1.0))

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32

    static let radius8: CGFloat = 8
    static let radius12: CGFloat = 12

    static func headerFont(_ size: CGFloat) -> Font {
        Font(headerUIFont(size) as CTFont)
    }

    static func bodyFont(_ size: CGFloat = 16) -> Font {
        .custom(rooftopRegularFontName, size: size, relativeTo: size <= 12 ? .caption : .body)
    }

    static func bodyMediumFont(_ size: CGFloat = 16) -> Font {
        .custom(rooftopMediumFontName, size: size, relativeTo: size <= 12 ? .caption : .body)
    }

    static func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: headerUIFont(17)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: headerUIFont(34)
        ]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
        navigationBar.tintColor = UIColor(accent)
    }

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func headerUIFont(_ size: CGFloat) -> UIFont {
        scaledUIFont(named: halvarFontName,
                     size: size,
                     textStyle: size >= 34 ? .largeTitle : (size >= 24 ? .title1 : .headline),
                     fallbackWeight: .bold)
    }

    private static func scaledUIFont(named fontName: String,
                                     size: CGFloat,
                                     textStyle: UIFont.TextStyle,
                                     fallbackWeight: UIFont.Weight) -> UIFont {
        let baseFont = UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallbackWeight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: baseFont)
    }
}

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.radius12)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}

struct AppInputFieldModifier: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, 14)
            .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.radius12)
                    .stroke(isFocused ? AppTheme.accent : AppTheme.border, lineWidth: isFocused ? 2 : 1)
            }
            .shadow(color: Color.black.opacity(isFocused ? 0.10 : 0.04), radius: isFocused ? 10 : 4, y: 2)
            .foregroundStyle(AppTheme.textPrimary)
            .tint(AppTheme.accent)
    }
}

struct AppPrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primaryButtonBackground)
            .foregroundStyle(.white)
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }

    func appInputField(isFocused: Bool) -> some View {
        modifier(AppInputFieldModifier(isFocused: isFocused))
    }

    func appPrimaryButton() -> some View {
        modifier(AppPrimaryButtonModifier())
    }
}
