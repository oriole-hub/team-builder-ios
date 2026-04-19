//
//  PulseView.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import SwiftUI

struct PulseView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var mood = 4.0
    @State private var stress = 3.0
    @State private var workload = 4.0
    @State private var recognition = 2.0
    @State private var collaboration = 4.0
    @State private var leaveIntent = 2.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("Еженедельный опрос")
                        .font(AppTheme.headerFont(17))
                        .foregroundStyle(AppTheme.textPrimary)

                    pulseSlider(title: "Настроение", value: $mood)
                    pulseSlider(title: "Стресс", value: $stress)
                    pulseSlider(title: "Нагрузка", value: $workload)
                    pulseSlider(title: "Признание", value: $recognition)
                    pulseSlider(title: "Взаимодействие", value: $collaboration)
                    pulseSlider(title: "Желание уйти", value: $leaveIntent)

                    Button("Отправить") {
                        Task {
                            await appModel.submitPulse(
                                mood: mood,
                                stress: stress,
                                workload: workload,
                                recognition: recognition,
                                collaboration: collaboration,
                                leaveIntent: leaveIntent
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
        .navigationTitle("Опрос Pulse")
        .task(id: appModel.employeeDashboard?.latestPulse) {
            if let pulse = appModel.employeeDashboard?.latestPulse {
                mood = Double(pulse.mood)
                stress = Double(pulse.stress)
                workload = Double(pulse.workload)
                recognition = Double(pulse.recognition)
                collaboration = Double(pulse.collaboration)
                leaveIntent = Double(pulse.leaveIntent)
            }
        }
    }

    private func pulseSlider(title: String, value: Binding<Double>) -> some View {
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

            Slider(value: value, in: 1...5, step: 1)
                .tint(AppTheme.secondaryAccent)
        }
    }
}

struct PulseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PulseView()
                .environmentObject(AppModel())
        }
    }
}
