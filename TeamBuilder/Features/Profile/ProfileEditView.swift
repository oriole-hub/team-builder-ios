//
//  ProfileEditView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appModel: AppModel

    @State private var jobTitle = ""
    @State private var department = ""
    @State private var workStyle = ""
    @State private var growthFocus = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing16) {
                if let profile = appModel.employeeDashboard?.profile {
                    form(profile: profile)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: appModel.employeeDashboard?.profile) {
            if let profile = appModel.employeeDashboard?.profile {
                jobTitle = profile.jobTitle
                department = profile.department
                workStyle = profile.workStyle
                growthFocus = profile.growthFocus
            }
        }
    }

    private func form(profile: EmployeeProfileData) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Профиль сотрудника")
                .font(AppTheme.headerFont(17))
                .foregroundStyle(AppTheme.textPrimary)

            profileField(title: "Должность", text: $jobTitle)
            profileField(title: "Отдел", text: $department)
            profileField(title: "Стиль работы", text: $workStyle)
            profileField(title: "Фокус развития", text: $growthFocus)

            Button("Сохранить профиль") {
                Task {
                    let isUpdated = await appModel.updateProfile(
                        jobTitle: jobTitle,
                        department: department,
                        workStyle: workStyle,
                        growthFocus: growthFocus
                    )

                    if isUpdated {
                        dismiss()
                    }
                }
            }
            .appPrimaryButton()

            Text("Стаж: \(profile.tenure) • Формат работы: \(profile.workMode)")
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }

    private func profileField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text(title)
                .font(AppTheme.bodyMediumFont())
                .foregroundStyle(AppTheme.textSecondary)

            TextField(title, text: text, axis: .vertical)
                .font(AppTheme.bodyFont())
                .padding()
                .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileEditView()
                .environmentObject(AppModel())
        }
    }
}
