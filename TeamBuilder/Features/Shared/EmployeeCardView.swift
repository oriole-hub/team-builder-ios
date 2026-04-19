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

            if !employee.roleTitle.isEmpty {
                Text(employee.roleTitle)
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: AppTheme.spacing12) {
                if let chemistryFit = employee.chemistryFit {
                    badge(title: "Совпадение", value: chemistryFit, color: AppTheme.success)
                }
                if let burnoutRisk = employee.burnoutRisk {
                    badge(title: "Выгорание", value: burnoutRisk, color: AppTheme.danger)
                }
                if let potential = employee.potential {
                    badge(title: "Потенциал", value: potential, color: AppTheme.secondaryAccent)
                }
            }

            if let summary = employee.summary, !summary.isEmpty {
                Text(summary)
                    .font(AppTheme.bodyMediumFont(14))
                    .foregroundStyle(AppTheme.textSecondary)
            }
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
                summary: "Дайте больше признания и самостоятельности."
            )
        )
    }
}
