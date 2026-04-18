//
//  ManagerSummaryView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct ManagerSummaryView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                if let dashboard = appModel.managerDashboard {
                    summaryCards(summary: dashboard.summary)
                    recommendations(items: dashboard.recommendations)
                    teamMovers(employees: dashboard.employees)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Сводка команды")
        .refreshable {
            Task {
                await appModel.refreshData()
            }
        }
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button {
//                    Task {
//                        await appModel.refreshData()
//                    }
//                } label: {
//                    Image(systemName: "arrow.clockwise")
//                }
//            }
//        }
    }

    private func summaryCards(summary: TeamDashboardResponse) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text(summary.teamName)
                .font(AppTheme.headerFont(28))
                .foregroundStyle(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                managerMetric(title: "Химия", value: "\(summary.chemistryScore)")
                managerMetric(title: "Риск конфликта", value: "\(summary.conflictRisk)")
                managerMetric(title: "Риск ухода", value: "\(summary.attritionRisk)")
                managerMetric(title: "Преемственность", value: "\(summary.successionScore)")
            }
        }
        .appCard()
    }

    private func recommendations(items: [RecommendationItem]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Рекомендуемые действия")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(items) { item in
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text(item.title)
                        .font(AppTheme.headerFont(16))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(item.message)
                        .font(AppTheme.bodyFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appCard()
            }
        }
    }

    private func teamMovers(employees: [EmployeeSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Кратко по людям")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(employees) { employee in
                EmployeeCardView(employee: employee)
            }
        }
    }

    private func managerMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
            Text(title)
                .font(AppTheme.bodyMediumFont(12))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(AppTheme.headerFont(24))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing12)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
    }
}

struct ManagerSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ManagerSummaryView()
                .environmentObject(AppModel())
        }
    }
}
