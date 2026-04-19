//
//  ManagerRootView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct ManagerRootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.selectedManagerTab) {
            NavigationStack {
                ManagerTeamView()
            }
            .tabItem {
                Label("Команда", systemImage: "person.3.fill")
            }
            .tag(ManagerTab.team)

            NavigationStack {
                ManagerRisksView()
            }
            .tabItem {
                Label("Риски", systemImage: "exclamationmark.shield.fill")
            }
            .tag(ManagerTab.risks)

            NavigationStack {
                NotificationsView()
            }
            .tabItem {
                Label("Уведомления", systemImage: "bell.fill")
            }
            .badge(appModel.unreadNotificationCount)
            .tag(ManagerTab.notifications)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Профиль", systemImage: "person.crop.circle")
            }
            .tag(ManagerTab.profile)
        }
    }
}

struct ManagerRootView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerRootView()
            .environmentObject(AppModel())
    }
}
