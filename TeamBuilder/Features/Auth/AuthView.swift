//
//  AuthView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct AuthView: View {
    private enum Field: Hashable {
        case email
        case password
    }

    @EnvironmentObject private var appModel: AppModel

    @State private var email = "employee@demo.team"
    @State private var password = "demo123"
    @State private var inviteCode = "invite-employee"
    @State private var fullName = "Алина Петрова"
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            Text("Почта")
                                .font(AppTheme.bodyMediumFont(14))
                                .foregroundStyle(AppTheme.textSecondary)

                            TextField("employee@demo.team", text: $email)
                                .font(AppTheme.bodyFont())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .focused($focusedField, equals: .email)
                                .appInputField(isFocused: focusedField == .email)
                        }

                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            Text("Пароль")
                                .font(AppTheme.bodyMediumFont(14))
                                .foregroundStyle(AppTheme.textSecondary)

                            SecureField("Введите пароль", text: $password)
                                .font(AppTheme.bodyFont())
                                .focused($focusedField, equals: .password)
                                .appInputField(isFocused: focusedField == .password)
                        }

                        
                        Button("Демо сотрудника") {
                            Task {
                                await appModel.runDemoFlow(for: .employee)
                            }
                        }
                        .appPrimaryButton()
                        
                        Button("Демо руководителя") {
                            Task {
                                await appModel.runDemoFlow(for: .manager)
                            }
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task {
                                await appModel.signIn(email: email, password: password)
                            }
                        } label: {
                            HStack {
                                Text("Продолжить")
                                Spacer()
                                if appModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                        }
                        .appPrimaryButton()
                    }
                    .appCard()

//                    VStack(alignment: .leading, spacing: AppTheme.spacing12) {
//                        Text("Принять приглашение")
//                            .font(.headline)
//                            .foregroundStyle(AppTheme.textPrimary)
//
//                        TextField("Код приглашения", text: $inviteCode)
//                            .textInputAutocapitalization(.never)
//                            .padding()
//                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
//                            .foregroundStyle(AppTheme.textPrimary)
//
//                        TextField("Полное имя", text: $fullName)
//                            .padding()
//                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
//                            .foregroundStyle(AppTheme.textPrimary)
//
//                        Button("Активировать доступ сотрудника") {
//                            Task {
//                                await appModel.acceptInvitation(code: inviteCode, fullName: fullName)
//                            }
//                        }
//                        .appPrimaryButton()
//                    }
//                    .appCard()
                }
                .padding(AppTheme.spacing16)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Добро пожаловать")
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AppModel())
    }
}
