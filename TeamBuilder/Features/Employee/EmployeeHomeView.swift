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
                    if dashboard.latestPulse != nil {
                        latestPulse(dashboard: dashboard)
                    }
                    if dashboard.disc != nil || dashboard.motivation != nil {
                        assessments(dashboard: dashboard)
                    }
                    profileHighlights(dashboard: dashboard)
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
                if let disc = dashboard.disc {
                    metric(title: "DISC", value: disc.dominantStyle)
                }
                if let motivation = dashboard.motivation {
                    metric(title: "Рост", value: "\(motivation.growth)")
                }
                if let pulse = dashboard.latestPulse {
                    metric(title: "Риск ухода", value: "\(pulse.leaveIntent)")
                }
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
                metric(title: "Настроение", value: "\(dashboard.latestPulse?.mood ?? 0)")
                metric(title: "Стресс", value: "\(dashboard.latestPulse?.stress ?? 0)")
                metric(title: "Признание", value: "\(dashboard.latestPulse?.recognition ?? 0)")
            }

            Text("Отправлено \(dashboard.latestPulse?.submittedAt.formatted(date: .abbreviated, time: .omitted) ?? "недоступно")")
                .font(AppTheme.bodyMediumFont(14))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }

    private func assessments(dashboard: EmployeeDashboardData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Последние оценки")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            if let disc = dashboard.disc {
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text("DISC")
                        .font(AppTheme.headerFont(16))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Доминирующий стиль: \(disc.dominantStyle)")
                        .font(AppTheme.bodyMediumFont(14))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appCard()
            }

            if let motivation = dashboard.motivation {
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text("Мотивация")
                        .font(AppTheme.headerFont(16))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Рост \(motivation.growth) • Автономия \(motivation.autonomy) • Стабильность \(motivation.stability) • Вознаграждение \(motivation.reward)")
                        .font(AppTheme.bodyMediumFont(14))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appCard()
            }
        }
    }

    private func profileHighlights(dashboard: EmployeeDashboardData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Профиль")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            if !dashboard.profile.workStyle.isEmpty {
                infoRow(title: "Стиль работы", value: dashboard.profile.workStyle)
            }

            if !dashboard.profile.growthFocus.isEmpty {
                infoRow(title: "Фокус развития", value: dashboard.profile.growthFocus)
            }

            Text("Стаж: \(dashboard.profile.tenure.isEmpty ? "не указан" : dashboard.profile.tenure) • Формат: \(dashboard.profile.workMode.isEmpty ? "не указан" : dashboard.profile.workMode)")
                .font(AppTheme.bodyMediumFont(14))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
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

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
            Text(title)
                .font(AppTheme.bodyMediumFont(12))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textPrimary)
        }
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
