//
//  EmployeeRootView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct EmployeeRootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.selectedEmployeeTab) {
            NavigationStack {
                EmployeeHomeView()
            }
            .tabItem {
                Label("Главная", systemImage: "house.fill")
            }
            .tag(EmployeeTab.home)

            NavigationStack {
                AssessmentsView()
            }
            .tabItem {
                Label("Опросы", systemImage: "chart.bar.doc.horizontal")
            }
            .tag(EmployeeTab.assessments)

            NavigationStack {
                PulseView()
            }
            .tabItem {
                Label("Опрос pulse", systemImage: "waveform.path.ecg")
            }
            .tag(EmployeeTab.pulse)

            NavigationStack {
                NotificationsView()
            }
            .tabItem {
                Label("Уведомления", systemImage: "bell.fill")
            }
            .badge(appModel.unreadNotificationCount)
            .tag(EmployeeTab.notifications)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Профиль", systemImage: "person.crop.circle")
            }
            .tag(EmployeeTab.profile)
        }
    }
}

struct EmployeeRootView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeRootView()
            .environmentObject(AppModel())
    }
}
