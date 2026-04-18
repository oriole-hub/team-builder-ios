//
//  EmployeeDetailView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct EmployeeDetailView: View {
    let employee: EmployeeSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                EmployeeCardView(employee: employee)

                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("Рекомендация руководителю")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(employee.topRecommendation)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appCard()
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle(employee.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmployeeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EmployeeDetailView(
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
}
