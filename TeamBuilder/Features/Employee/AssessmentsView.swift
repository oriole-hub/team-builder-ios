//
//  AssessmentsView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct AssessmentsView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var dominance = 62.0
    @State private var influence = 78.0
    @State private var steadiness = 55.0
    @State private var compliance = 48.0

    @State private var growth = 84.0
    @State private var autonomy = 74.0
    @State private var stability = 42.0
    @State private var reward = 61.0

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing16) {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("DISC")
                        .font(AppTheme.headerFont(17))
                        .foregroundStyle(AppTheme.textPrimary)

                    slider(title: "Доминирование", value: $dominance)
                    slider(title: "Влияние", value: $influence)
                    slider(title: "Стабильность", value: $steadiness)
                    slider(title: "Соответствие", value: $compliance)

                    Button("Отправить DISC") {
                        Task {
                            await appModel.submitDisc(
                                dominance: dominance,
                                influence: influence,
                                steadiness: steadiness,
                                compliance: compliance
                            )
                        }
                    }
                    .appPrimaryButton()
                }
                .appCard()

                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("Мотивация")
                        .font(AppTheme.headerFont(17))
                        .foregroundStyle(AppTheme.textPrimary)

                    slider(title: "Рост", value: $growth)
                    slider(title: "Автономия", value: $autonomy)
                    slider(title: "Стабильность", value: $stability)
                    slider(title: "Вознаграждение", value: $reward)

                    Button("Отправить мотивацию") {
                        Task {
                            await appModel.submitMotivation(
                                growth: growth,
                                autonomy: autonomy,
                                stability: stability,
                                reward: reward
                            )
                        }
                    }
                    .appPrimaryButton()
                }
                .appCard()
            }
            .padding(AppTheme.spacing16)
        }
        .background(AppTheme.background)
        .navigationTitle("Опросы")
        .task(id: appModel.employeeDashboard) {
            if let disc = appModel.employeeDashboard?.disc {
                dominance = Double(disc.dominance)
                influence = Double(disc.influence)
                steadiness = Double(disc.steadiness)
                compliance = Double(disc.compliance)
            }

            if let motivation = appModel.employeeDashboard?.motivation {
                growth = Double(motivation.growth)
                autonomy = Double(motivation.autonomy)
                stability = Double(motivation.stability)
                reward = Double(motivation.reward)
            }
        }
    }

    private func slider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            HStack {
                Text(title)
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(AppTheme.bodyMediumFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Slider(value: value, in: 0...100, step: 1)
                .tint(AppTheme.accent)
        }
    }
}

struct AssessmentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AssessmentsView()
                .environmentObject(AppModel())
        }
    }
}
