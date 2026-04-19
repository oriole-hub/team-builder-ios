//
//  ManagerTeamView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct ManagerTeamView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                if let dashboard = appModel.managerDashboard {
                    summaryCards(summary: dashboard.summary)
                    teamSection

                    if dashboard.employees.isEmpty {
                        emptyTeamState
                    } else {
                        ForEach(dashboard.employees) { employee in
                            Button {
                                appModel.presentedEmployee = employee
                            } label: {
                                EmployeeCardView(employee: employee)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Команда")
        .refreshable {
            await appModel.refreshData()
        }
        .sheet(item: $appModel.presentedEmployee) { employee in
            NavigationStack {
                EmployeeDetailView(employee: employee)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var teamSection: some View {
        Text("Состав команды")
            .font(AppTheme.headerFont(20))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.top, AppTheme.spacing8)
    }

    private var emptyTeamState: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Команда пока пустая")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Сотрудники появятся здесь после загрузки данных команды.")
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }

    private func summaryCards(summary: TeamDashboardResponse) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text(summary.teamName)
                .font(AppTheme.headerFont(28))
                .foregroundStyle(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                if let chemistryScore = summary.chemistryScore {
                    managerMetric(title: "Химия", value: "\(chemistryScore)")
                }
                if let conflictRisk = summary.conflictRisk {
                    managerMetric(title: "Риск конфликта", value: "\(conflictRisk)")
                }
                if let attritionRisk = summary.attritionRisk {
                    managerMetric(title: "Риск ухода", value: "\(attritionRisk)")
                }
                if let successionScore = summary.successionScore {
                    managerMetric(title: "Преемственность", value: "\(successionScore)")
                }
            }
        }
        .appCard()
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

struct ManagerTeamView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ManagerTeamView()
                .environmentObject(AppModel())
        }
    }
}
