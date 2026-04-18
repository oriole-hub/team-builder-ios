//
//  ManagerTeamView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct ManagerTeamView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                if let employees = appModel.managerDashboard?.employees {
                    ForEach(employees) { employee in
                        Button {
                            appModel.presentedEmployee = employee
                        } label: {
                            EmployeeCardView(employee: employee)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Команда")
        .sheet(item: $appModel.presentedEmployee) { employee in
            NavigationStack {
                EmployeeDetailView(employee: employee)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct ManagerTeamView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ManagerTeamView()
                .environmentObject(AppModel())
        }
    }
}
