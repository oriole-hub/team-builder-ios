//
//  ManagerRisksView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct ManagerRisksView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                if let dashboard = appModel.managerDashboard {
                    ForEach(dashboard.risks) { risk in
                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            HStack {
                                Text(risk.title)
                                    .font(AppTheme.headerFont(16))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text(risk.severity)
                                    .font(AppTheme.headerFont(12))
                                    .padding(.horizontal, AppTheme.spacing8)
                                    .padding(.vertical, AppTheme.spacing4)
                                    .background(color(for: risk.severity).opacity(0.2), in: Capsule())
                                    .foregroundStyle(color(for: risk.severity))
                            }

                            Text(risk.message)
                                .font(AppTheme.bodyFont())
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .appCard()
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Риски")
    }

    private func color(for severity: String) -> Color {
        switch severity.lowercased() {
        case "high", "высокий":
            return AppTheme.danger
        case "medium", "средний":
            return AppTheme.accent
        default:
            return AppTheme.secondaryAccent
        }
    }
}

struct ManagerRisksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ManagerRisksView()
                .environmentObject(AppModel())
        }
    }
}
