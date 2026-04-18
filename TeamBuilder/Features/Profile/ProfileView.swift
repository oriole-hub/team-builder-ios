//
//  ProfileView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                if let session = appModel.session {
                    identity(session: session)
                    if session.user.role == .employee, let dashboard = appModel.employeeDashboard {
                        employeeProfile(profile: dashboard.profile)
                    }
                    deepLinkExamples
                    Button("Выйти", role: .destructive) {
                        appModel.signOut()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Профиль")
    }

    private func identity(session: UserSession) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text(session.user.fullName)
                .font(AppTheme.headerFont(24))
                .foregroundStyle(AppTheme.textPrimary)

            Text(session.user.email)
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)

            Text(session.user.role.rawValue)
                .font(AppTheme.headerFont(14))
                .padding(.horizontal, AppTheme.spacing8)
                .padding(.vertical, AppTheme.spacing4)
                .background(AppTheme.accent.opacity(0.2), in: Capsule())
                .foregroundStyle(AppTheme.accent)
        }
        .appCard()
    }

    private func employeeProfile(profile: EmployeeProfileData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            NavigationLink {
                ProfileEditView()
            } label: {
                HStack(alignment: .center, spacing: AppTheme.spacing8) {
                    Image(systemName: "pencil")
                        .frame(width: 16, height: 16)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Редактировать профиль")
                        .font(AppTheme.bodyFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
        .appCard()
    }


    private var deepLinkExamples: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Deeplink-ссылки")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            Button("Открыть уведомления") {
                Task {
                    await appModel.handleURL(URL(string: "teambuilder://notifications")!)
                }
            }
            .buttonStyle(.bordered)

            Button("Открыть опрос pulse") {
                Task {
                    await appModel.handleURL(URL(string: "teambuilder://pulse")!)
                }
            }
            .buttonStyle(.bordered)

            Button("Открыть риски команды") {
                Task {
                    await appModel.handleURL(URL(string: "teambuilder://risks")!)
                }
            }
            .buttonStyle(.bordered)
        }
        .appCard()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(AppModel())
        }
    }
}
