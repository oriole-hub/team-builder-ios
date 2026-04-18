//
//  AppTheme.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI
import UIKit

enum AppTheme {
    static let background = dynamicColor(light: UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0),
                                         dark: UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0))
    static let surface = dynamicColor(light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                                      dark: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0))
    static let elevatedSurface = dynamicColor(light: UIColor(red: 0.92, green: 0.93, blue: 0.96, alpha: 1.0),
                                              dark: UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0))
    static let accent = Color(red: 1.0, green: 0.2039, blue: 0.5843)
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

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
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

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }
}
