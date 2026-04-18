//
//  AuthView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var email = "employee@demo.team"
    @State private var password = "demo123"
    @State private var inviteCode = "invite-employee"
    @State private var fullName = "Алина Петрова"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                        Text("Вход")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)

                        TextField("Почта", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
                            .foregroundStyle(AppTheme.textPrimary)

                        SecureField("Пароль", text: $password)
                            .padding()
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radius12))
                            .foregroundStyle(AppTheme.textPrimary)

                        
                        Button("Демо сотрудника") {
                            email = "employee@demo.team"
                            password = "demo123"
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Демо руководителя") {
                            email = "manager@demo.team"
                            password = "demo123"
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
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
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
//                        .buttonStyle(.borderedProminent)
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
