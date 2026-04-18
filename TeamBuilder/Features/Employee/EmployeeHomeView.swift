//
//  EmployeeHomeView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct EmployeeHomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                if let dashboard = appModel.employeeDashboard {
                    hero(dashboard: dashboard)
                    latestPulse(dashboard: dashboard)
                    recommendations(dashboard: dashboard)
                    goals(dashboard: dashboard)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Мое пространство")
        .refreshable {
            Task {
                await appModel.refreshData()
            }
        }
    }

    private func hero(dashboard: EmployeeDashboardData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text(dashboard.profile.fullName)
                .font(AppTheme.headerFont(28))
                .foregroundStyle(AppTheme.textPrimary)

            Text("\(dashboard.profile.jobTitle) • \(dashboard.profile.department)")
                .font(AppTheme.bodyMediumFont(16))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.spacing12) {
                metric(title: "DISC", value: dashboard.disc.dominantStyle)
                metric(title: "Рост", value: "\(dashboard.motivation.growth)")
                metric(title: "Риск ухода", value: "\(dashboard.latestPulse.leaveIntent)")
            }
        }
        .appCard()
    }

    private func latestPulse(dashboard: EmployeeDashboardData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Последний опрос pulse")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: AppTheme.spacing12) {
                metric(title: "Настроение", value: "\(dashboard.latestPulse.mood)")
                metric(title: "Стресс", value: "\(dashboard.latestPulse.stress)")
                metric(title: "Признание", value: "\(dashboard.latestPulse.recognition)")
            }

            Text("Отправлено \(dashboard.latestPulse.submittedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(AppTheme.bodyMediumFont(14))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }

    private func recommendations(dashboard: EmployeeDashboardData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Рекомендации")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(dashboard.recommendations) { item in
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    HStack {
                        Text(item.title)
                            .font(AppTheme.headerFont(16))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text(item.priority)
                            .font(AppTheme.headerFont(12))
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(AppTheme.accent.opacity(0.2), in: Capsule())
                            .foregroundStyle(AppTheme.accent)
                    }

                    Text(item.message)
                        .font(AppTheme.bodyMediumFont(14))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appCard()
            }
        }
    }

    private func goals(dashboard: EmployeeDashboardData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Цели и развитие")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(dashboard.goals) { goal in
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text(goal.title)
                        .font(AppTheme.headerFont(16))
                        .foregroundStyle(AppTheme.textPrimary)

                    ProgressView(value: goal.progress)
                        .tint(AppTheme.secondaryAccent)

                    Text(goal.dueLabel)
                        .font(AppTheme.bodyMediumFont(14))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appCard()
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
            Text(title)
                .font(AppTheme.bodyMediumFont(12))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(AppTheme.headerFont(20))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing12)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
    }
}

struct EmployeeHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EmployeeHomeView()
                .environmentObject(AppModel())
        }
    }
}
