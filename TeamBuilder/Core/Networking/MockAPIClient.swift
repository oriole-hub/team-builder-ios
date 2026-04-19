//
//  MockAPIClient.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

final class MockAPIClient: APIClient, NetworkStateControlling {
    var isNetworkReachable = true
    var authTokens: SessionTokens?
    var onTokenRefresh: ((SessionTokens) -> Void)?

    private let companyID = UUID(uuidString: "2A3F77E1-5E59-4699-86D2-D77889F4EF65") ?? UUID()
    private let teamID = UUID(uuidString: "1E50A64E-83A1-4FE2-950D-10C950F702A0") ?? UUID()
    private let employeeID = UUID(uuidString: "7B68B830-8A28-4A26-9691-56F25D4B9D52") ?? UUID()
    private let managerID = UUID(uuidString: "6CC674BF-13BB-4E7F-BF18-33A604593B86") ?? UUID()

    private var currentUser: AppUser?
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
        mood: 4,
        stress: 3,
        workload: 4,
        recognition: 2,
        collaboration: 4,
        leaveIntent: 2,
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

    func signIn(request: SignInRequest) async throws -> UserSession {
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

        let tokens = SessionTokens(
            accessToken: "demo-access-\(user.id.uuidString.lowercased())",
            refreshToken: "demo-refresh-\(user.id.uuidString.lowercased())"
        )
        authTokens = tokens
        currentUser = user
        return UserSession(user: user, tokens: tokens)
    }

    func acceptInvitation(code: String, fullName: String) async throws -> UserSession {
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

        let tokens = SessionTokens(
            accessToken: "invite-access-\(user.id.uuidString.lowercased())",
            refreshToken: "invite-refresh-\(user.id.uuidString.lowercased())"
        )
        authTokens = tokens
        currentUser = user
        return UserSession(user: user, tokens: tokens)
    }

    func fetchCurrentUser() async throws -> AppUser {
        try await simulateLatency()
        guard let currentUser else { throw APIClientError.unauthorized }
        return currentUser
    }

    func fetchNotifications() async throws -> [AppNotification] {
        try await simulateLatency()
        return notificationsStore
    }

    func fetchEmployeeProfile(employeeID: UUID) async throws -> EmployeeProfileData {
        try await simulateLatency()
        return employeeProfile
    }

    func fetchLatestDisc(employeeID: UUID) async throws -> DiscResult? {
        try await simulateLatency()
        return disc
    }

    func fetchLatestMotivation(employeeID: UUID) async throws -> MotivationResult? {
        try await simulateLatency()
        return motivation
    }

    func fetchLatestPulse() async throws -> PulseEntry? {
        try await simulateLatency()
        return pulse
    }

    func submitDisc(request: DiscSubmissionRequest) async throws -> DiscResult? {
        try await simulateLatency()
        disc = DiscResult(
            dominance: request.answers["dominance"]?.intValue ?? disc.dominance,
            influence: request.answers["influence"]?.intValue ?? disc.influence,
            steadiness: request.answers["steadiness"]?.intValue ?? disc.steadiness,
            compliance: request.answers["compliance"]?.intValue ?? disc.compliance
        )
        return disc
    }

    func submitMotivation(request: MotivationSubmissionRequest) async throws -> MotivationResult? {
        try await simulateLatency()
        motivation = MotivationResult(
            growth: request.answers["growth"]?.intValue ?? motivation.growth,
            autonomy: request.answers["autonomy"]?.intValue ?? motivation.autonomy,
            stability: request.answers["stability"]?.intValue ?? motivation.stability,
            reward: request.answers["reward"]?.intValue ?? motivation.reward
        )
        return motivation
    }

    func submitPulse(request: PulseSubmissionRequest) async throws -> PulseEntry? {
        try await simulateLatency()
        pulse = PulseEntry(
            mood: request.mood,
            stress: request.stress,
            workload: request.workload,
            recognition: request.recognition,
            collaboration: request.relationships,
            leaveIntent: request.intentToLeave,
            submittedAt: Date()
        )
        return pulse
    }

    func updateEmployeeProfile(employeeID: UUID, request: EmployeeProfileUpdateRequest) async throws -> EmployeeProfileData {
        try await simulateLatency()
        employeeProfile = EmployeeProfileData(
            fullName: employeeProfile.fullName,
            jobTitle: request.profile["job_title"]?.stringValue ?? employeeProfile.jobTitle,
            department: request.profile["department"]?.stringValue ?? employeeProfile.department,
            workStyle: request.profile["work_style"]?.stringValue ?? employeeProfile.workStyle,
            growthFocus: request.profile["growth_focus"]?.stringValue ?? employeeProfile.growthFocus,
            tenure: employeeProfile.tenure,
            workMode: request.profile["work_format"]?.stringValue ?? employeeProfile.workMode
        )
        return employeeProfile
    }

    func fetchTeams() async throws -> [TeamDashboardResponse] {
        try await simulateLatency()
        return [
            TeamDashboardResponse(
                teamID: teamID,
                teamName: "Команда роста",
                chemistryScore: 78,
                conflictRisk: 43,
                attritionRisk: 37,
                talentPoolScore: 69,
                successionScore: 61
            )
        ]
    }

    func fetchTeam(teamID: UUID) async throws -> TeamDashboardResponse? {
        try await simulateLatency()
        return TeamDashboardResponse(
            teamID: teamID,
            teamName: "Команда роста",
            chemistryScore: 78,
            conflictRisk: 43,
            attritionRisk: 37,
            talentPoolScore: 69,
            successionScore: 61
        )
    }

    func fetchTeamPulseSummary(teamID: UUID) async throws -> [EmployeeSnapshot] {
        try await simulateLatency()
        return sampleEmployees
    }

    func fetchTeamAnalytics(teamID: UUID) async throws -> TeamDashboardResponse {
        try await simulateLatency()
        return TeamDashboardResponse(
            teamID: teamID,
            teamName: "Команда роста",
            chemistryScore: 78,
            conflictRisk: 43,
            attritionRisk: 37,
            talentPoolScore: 69,
            successionScore: 61
        )
    }

    func fetchTeamRisks(teamID: UUID) async throws -> [TeamRiskItem] {
        try await simulateLatency()
        return [
            TeamRiskItem(id: UUID(), title: "Падение признания", severity: "Высокий", message: "У двух сотрудников оценка признания ниже 3. Нужны быстрые 1:1 встречи."),
            TeamRiskItem(id: UUID(), title: "Разрыв в преемственности", severity: "Средний", message: "Только один сотрудник близок к роли резервного лидера аналитики.")
        ]
    }

    func fetchTeamRoleMap(teamID: UUID) async throws -> [EmployeeSnapshot] {
        try await simulateLatency()
        return sampleEmployees
    }

    func markNotificationRead(notificationID: UUID) async throws {
        try await simulateLatency()
        guard let index = notificationsStore.firstIndex(where: { $0.id == notificationID }) else {
            throw APIClientError.notFound
        }
        notificationsStore[index].isRead = true
    }

    private var sampleEmployees: [EmployeeSnapshot] {
        [
            EmployeeSnapshot(id: employeeID, fullName: employeeProfile.fullName, roleTitle: employeeProfile.jobTitle, chemistryFit: 84, burnoutRisk: 41, potential: 79, summary: "Нужны признание и больше самостоятельности."),
            EmployeeSnapshot(id: UUID(), fullName: "Иван Смирнов", roleTitle: "Аналитик роста", chemistryFit: 73, burnoutRisk: 58, potential: 82, summary: "Снизьте переключение контекста и сбалансируйте сроки."),
            EmployeeSnapshot(id: UUID(), fullName: "Мила Соколова", roleTitle: "Менеджер жизненного цикла", chemistryFit: 77, burnoutRisk: 33, potential: 68, summary: "Дайте больше автономии в планировании кампаний.")
        ]
    }

    private func simulateLatency() async throws {
        guard isNetworkReachable else {
            throw APIClientError.networkUnavailable
        }

        try await Task.sleep(nanoseconds: 150_000_000)
    }
}
