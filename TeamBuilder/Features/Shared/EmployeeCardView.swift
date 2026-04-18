//
//  EmployeeCardView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct EmployeeCardView: View {
    let employee: EmployeeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text(employee.fullName)
                .font(AppTheme.headerFont(16))
                .foregroundStyle(AppTheme.textPrimary)

            Text(employee.roleTitle)
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.spacing12) {
                badge(title: "Совпадение", value: employee.chemistryFit, color: AppTheme.success)
                badge(title: "Выгорание", value: employee.burnoutRisk, color: AppTheme.danger)
                badge(title: "Потенциал", value: employee.potential, color: AppTheme.secondaryAccent)
            }

            Text(employee.topRecommendation)
                .font(AppTheme.bodyMediumFont(14))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }

    private func badge(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
            Text(title)
                .font(AppTheme.bodyMediumFont(12))
                .foregroundStyle(AppTheme.textSecondary)
            Text("\(value)")
                .font(AppTheme.headerFont(18))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing8)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
    }
}

struct EmployeeCardView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeCardView(
            employee: EmployeeSnapshot(
                id: UUID(),
                fullName: "Алина Петрова",
                roleTitle: "Продуктовый дизайнер",
                chemistryFit: 84,
                burnoutRisk: 41,
                potential: 79,
                topRecommendation: "Дайте больше признания и самостоятельности."
            )
        )
    }
}
