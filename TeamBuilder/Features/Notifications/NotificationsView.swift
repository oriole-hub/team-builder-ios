//
//  NotificationsView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        List {
            ForEach(appModel.notifications) { notification in
                Button {
                    if let deepLink = notification.deepLink, let url = URL(string: deepLink) {
                        Task {
                            await appModel.handleURL(url)
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        HStack {
                            Text(notification.title)
                                .font(AppTheme.headerFont(16))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            if !notification.isRead {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 10, height: 10)
                            }
                        }

                        Text(notification.message)
                            .font(AppTheme.bodyFont())
                            .foregroundStyle(AppTheme.textSecondary)

                        Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTheme.bodyFont(13))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.border)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !notification.isRead {
                            Button("Прочитано") {
                                Task {
                                    await appModel.markNotificationRead(notification)
                                }
                            }
                            .tint(AppTheme.accent)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Уведомления")
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationsView()
                .environmentObject(AppModel())
        }
    }
}
