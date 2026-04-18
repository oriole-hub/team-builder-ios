//
//  AppRootView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Group {
                if appModel.session == nil {
                    AuthView()
                } else if appModel.currentRole == .manager {
                    ManagerRootView()
                } else {
                    EmployeeRootView()
                }
            }
        }
        .alert("Team Builder", isPresented: $appModel.isAlertPresented) {
            Button("ОК", role: .cancel) { }
        } message: {
            Text(appModel.alertMessage)
        }
        .overlay(alignment: .top) {
            if appModel.isSyncingQueue {
                ProgressView("Синхронизация")
                    .padding(.horizontal, AppTheme.spacing24)
                    .padding(.vertical, AppTheme.spacing12)
                    .background(AppTheme.surface, in: Capsule())
                    .padding(.top, AppTheme.spacing12)
            }
        }
        .task {
            await appModel.bootstrap()
        }
        .onOpenURL { url in
            Task {
                await appModel.handleURL(url)
            }
        }
    }
}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
            .environmentObject(AppModel())
    }
}
