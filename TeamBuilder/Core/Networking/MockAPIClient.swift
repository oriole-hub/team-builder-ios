//
//  MockAPIClient.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

final class MockAPIClient: APIClient, NetworkStateControlling {
    var isNetworkReachable = true

    private let companyID = UUID(uuidString: "2A3F77E1-5E59-4699-86D2-D77889F4EF65") ?? UUID()
    private let teamID = UUID(uuidString: "1E50A64E-83A1-4FE2-950D-10C950F702A0") ?? UUID()
    private let employeeID = UUID(uuidString: "7B68B830-8A28-4A26-9691-56F25D4B9D52") ?? UUID()
    private let managerID = UUID(uuidString: "6CC674BF-13BB-4E7F-BF18-33A604593B86") ?? UUID()

    private var employeeProfile = EmployeeProfileData(
        fullName: "Алина Петрова",
        jobTitle: "Продуктовый дизайнер",
        department: "Команда роста",
        workStyle: "Нужны четкие приоритеты, быстрая обратная связь и плотная совместная работа.",
        growthFocus: "Развивать влияние на продукт и аналитику.",
        tenure: "1 год 8 месяцев",
        workMode: "Гибрид"
    )

    private var disc = DiscResult(dominance: 62, influence: 78, steadiness: 55, compliance: 48)
    private var motivation = MotivationResult(growth: 84, autonomy: 74, stability: 42, reward: 61)
    private var pulse = PulseEntry(
        mood: 72,
        stress: 58,
        workload: 67,
        recognition: 44,
        collaboration: 79,
        leaveIntent: 22,
        submittedAt: Date().addingTimeInterval(-86_400)
    )

    private var notificationsStore: [AppNotification] = [
        AppNotification(
            id: UUID(uuidString: "3C71B1A7-C41B-4601-B6CF-860661D213A7") ?? UUID(),
            title: "Напоминание о pulse",
            message: "Заполните pulse-опрос за эту неделю до вечера пятницы.",
            createdAt: Date().addingTimeInterval(-3_600),
            isRead: false,
            deepLink: "teambuilder://pulse"
        ),
        AppNotification(
            id: UUID(uuidString: "8D1140A2-209A-4C3F-8954-8C973FB4D2F0") ?? UUID(),
            title: "Действие для руководителя",
            message: "В команде роста снизилось ощущение признания. Запланируйте 1:1 с Алиной.",
            createdAt: Date().addingTimeInterval(-7_200),
            isRead: false,
            deepLink: "teambuilder://risks"
        )
    ]

    func signIn(request: SignInRequest) async throws -> ResponseEnvelope<UserSessionDTO> {
        try await simulateLatency()

        guard request.password == "demo123" else {
            throw APIClientError.unauthorized
        }

        let isManager = request.email.lowercased().contains("manager")
        let user = AppUser(
            id: isManager ? managerID : employeeID,
            fullName: isManager ? "Алексей Романов" : employeeProfile.fullName,
            email: request.email,
            role: isManager ? .manager : .employee,
            companyID: companyID,
            teamID: teamID
        )

        return envelope(
            data: UserSessionDTO(
                user: user,
                accessToken: "demo-access-\(user.id.uuidString.lowercased())",
                refreshToken: "demo-refresh-\(user.id.uuidString.lowercased())"
            )
        )
    }

    func acceptInvitation(code: String, fullName: String) async throws -> ResponseEnvelope<UserSessionDTO> {
        try await simulateLatency()

        guard code.lowercased() == "invite-employee" else {
            throw APIClientError.invalidState("Код приглашения недействителен.")
        }

        employeeProfile = EmployeeProfileData(
            fullName: fullName,
            jobTitle: employeeProfile.jobTitle,
            department: employeeProfile.department,
            workStyle: employeeProfile.workStyle,
            growthFocus: employeeProfile.growthFocus,
            tenure: employeeProfile.tenure,
            workMode: employeeProfile.workMode
        )

        let user = AppUser(
            id: employeeID,
            fullName: fullName,
            email: "\(fullName.replacingOccurrences(of: " ", with: ".").lowercased())@demo.team",
            role: .employee,
            companyID: companyID,
            teamID: teamID
        )

        return envelope(
            data: UserSessionDTO(
                user: user,
                accessToken: "invite-access-\(user.id.uuidString.lowercased())",
                refreshToken: "invite-refresh-\(user.id.uuidString.lowercased())"
            )
        )
    }

    func fetchEmployeeDashboard(userID: UUID) async throws -> ResponseEnvelope<EmployeeDashboardData> {
        try await simulateLatency()

        let data = EmployeeDashboardData(
            profile: employeeProfile,
            disc: disc,
            motivation: motivation,
            latestPulse: pulse,
            recommendations: [
                RecommendationItem(id: UUID(), title: "Защитите фокус-блоки", message: "Освободите два утра от внеплановых встреч, чтобы выровнять нагрузку.", priority: "Высокий"),
                RecommendationItem(id: UUID(), title: "Увеличьте признание", message: "Последний pulse показывает низкое ощущение признания. Попросите более быструю обратную связь по результатам работы.", priority: "Средний"),
                RecommendationItem(id: UUID(), title: "Дайте растущую задачу", message: "Вы готовы взять на себя небольшой исследовательский поток вместе с аналитикой.", priority: "Средний")
            ],
            goals: [
                GoalItem(id: UUID(), title: "Провести один полный цикл клиентских интервью", dueLabel: "Срок через 9 дней", progress: 0.7),
                GoalItem(id: UUID(), title: "Зафиксировать пробелы во внедрении дизайн-системы", dueLabel: "Срок через 2 недели", progress: 0.45)
            ]
        )

        return envelope(data: data)
    }

    func fetchManagerDashboard(userID: UUID) async throws -> ResponseEnvelope<ManagerDashboardData> {
        try await simulateLatency()

        let summary = TeamDashboardResponse(
            teamID: teamID,
            teamName: "Команда роста",
            chemistryScore: 78,
            conflictRisk: 43,
            attritionRisk: 37,
            talentPoolScore: 69,
            successionScore: 61
        )

        let risks = [
            TeamRiskItem(id: UUID(), title: "Падение признания", severity: "Высокий", message: "У двух сотрудников оценка признания ниже 50. Нужны быстрые 1:1 встречи."),
            TeamRiskItem(id: UUID(), title: "Напряжение между дизайном и разработкой", severity: "Средний", message: "Распределение DISC указывает на напряжение между людьми, ориентированными на скорость, и теми, кто сфокусирован на деталях."),
            TeamRiskItem(id: UUID(), title: "Разрыв в преемственности", severity: "Средний", message: "Только один сотрудник близок к роли резервного лидера аналитики.")
        ]

        let employees = [
            EmployeeSnapshot(id: employeeID, fullName: employeeProfile.fullName, roleTitle: employeeProfile.jobTitle, chemistryFit: 84, burnoutRisk: 41, potential: 79, topRecommendation: "Дайте больше признания и самостоятельности."),
            EmployeeSnapshot(id: UUID(), fullName: "Иван Смирнов", roleTitle: "Аналитик роста", chemistryFit: 73, burnoutRisk: 58, potential: 82, topRecommendation: "Снизьте переключение контекста и сбалансируйте сроки."),
            EmployeeSnapshot(id: UUID(), fullName: "Мила Соколова", roleTitle: "Менеджер жизненного цикла", chemistryFit: 77, burnoutRisk: 33, potential: 68, topRecommendation: "Дайте больше автономии в планировании кампаний.")
        ]

        let recommendations = [
            RecommendationItem(id: UUID(), title: "Проведите точечный раунд признания", message: "Самый сильный краткосрочный рычаг сейчас — признание. Закройте цикл по результатам последнего спринта.", priority: "Высокий"),
            RecommendationItem(id: UUID(), title: "Перераспределите ролевую нагрузку", message: "Уберите с дизайна ответственность за QA кампаний на ближайшие две недели.", priority: "Высокий"),
            RecommendationItem(id: UUID(), title: "Назначьте тень на преемственность", message: "Сведите Ивана с лидом аналитики на еженедельном прогнозировании.", priority: "Средний")
        ]

        return envelope(
            data: ManagerDashboardData(
                summary: summary,
                risks: risks,
                employees: employees,
                recommendations: recommendations
            )
        )
    }

    func fetchNotifications(userID: UUID) async throws -> ResponseEnvelope<[AppNotification]> {
        try await simulateLatency()
        return envelope(data: notificationsStore)
    }

    func submitDisc(request: DiscSubmissionRequest) async throws -> ResponseEnvelope<DiscResult> {
        try await simulateLatency()
        disc = DiscResult(
            dominance: request.dominance,
            influence: request.influence,
            steadiness: request.steadiness,
            compliance: request.compliance
        )
        return envelope(data: disc)
    }

    func submitMotivation(request: MotivationSubmissionRequest) async throws -> ResponseEnvelope<MotivationResult> {
        try await simulateLatency()
        motivation = MotivationResult(
            growth: request.growth,
            autonomy: request.autonomy,
            stability: request.stability,
            reward: request.reward
        )
        return envelope(data: motivation)
    }

    func submitPulse(request: PulseSubmissionRequest) async throws -> ResponseEnvelope<PulseEntry> {
        try await simulateLatency()
        pulse = PulseEntry(
            mood: request.mood,
            stress: request.stress,
            workload: request.workload,
            recognition: request.recognition,
            collaboration: request.collaboration,
            leaveIntent: request.leaveIntent,
            submittedAt: request.submittedAt
        )
        return envelope(data: pulse)
    }

    func updateEmployeeProfile(employeeID: UUID, request: EmployeeProfileUpdateRequest) async throws -> ResponseEnvelope<EmployeeProfileData> {
        try await simulateLatency()
        employeeProfile = EmployeeProfileData(
            fullName: employeeProfile.fullName,
            jobTitle: request.jobTitle,
            department: request.department,
            workStyle: request.workStyle,
            growthFocus: request.growthFocus,
            tenure: employeeProfile.tenure,
            workMode: employeeProfile.workMode
        )
        return envelope(data: employeeProfile)
    }

    func markNotificationRead(notificationID: UUID) async throws -> ResponseEnvelope<AppNotification> {
        try await simulateLatency()

        guard let index = notificationsStore.firstIndex(where: { $0.id == notificationID }) else {
            throw APIClientError.notFound
        }

        notificationsStore[index].isRead = true
        return envelope(data: notificationsStore[index])
    }

    private func simulateLatency() async throws {
        guard isNetworkReachable else {
            throw APIClientError.networkUnavailable
        }

        try await Task.sleep(nanoseconds: 250_000_000)
    }

    private func envelope<DataType: Codable>(data: DataType) -> ResponseEnvelope<DataType> {
        ResponseEnvelope(
            success: true,
            data: data,
            error: nil,
            meta: MetaPayload(
                requestID: UUID(),
                timestamp: Date(),
                page: nil,
                pageSize: nil,
                total: nil
            )
        )
    }
}
