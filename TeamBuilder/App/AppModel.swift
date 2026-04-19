//
//  AppModel.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    private static let demoModeKey = "team_builder.demo_mode"

    @Published private(set) var session: UserSession?
    @Published private(set) var employeeDashboard: EmployeeDashboardData?
    @Published private(set) var managerDashboard: ManagerDashboardData?
    @Published private(set) var notifications: [AppNotification] = []
    @Published var selectedEmployeeTab: EmployeeTab = .home
    @Published var selectedManagerTab: ManagerTab = .team
    @Published var isAlertPresented = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    @Published var isSyncingQueue = false
    @Published var presentedEmployee: EmployeeSnapshot?
    @Published var pendingInviteCode = ""

    private let primaryAPIClient: any APIClient & NetworkStateControlling
    private let demoAPIClient = MockAPIClient()
    private var apiClient: any APIClient & NetworkStateControlling
    private let keychainStore = KeychainStore()
    private let queueStore = OfflineQueueStore()
    private let defaults = UserDefaults.standard

    private let sessionKey = "team_builder.session"
    private let accessTokenKey = "team_builder.access_token"
    private let refreshTokenKey = "team_builder.refresh_token"

    init(primaryAPIClient: some APIClient & NetworkStateControlling, startInDemoMode: Bool = false) {
        self.primaryAPIClient = primaryAPIClient
        self.apiClient = startInDemoMode ? demoAPIClient : primaryAPIClient
        self.session = Self.loadSession(
            defaults: defaults,
            keychainStore: keychainStore,
            sessionKey: sessionKey,
            accessTokenKey: accessTokenKey,
            refreshTokenKey: refreshTokenKey
        )
        configureAPIClient(apiClient)
    }

    convenience init() {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            self.init(primaryAPIClient: MockAPIClient(), startInDemoMode: true)
        } else {
            let startInDemoMode = UserDefaults.standard.bool(forKey: Self.demoModeKey)
            self.init(primaryAPIClient: LiveAPIClient(), startInDemoMode: startInDemoMode)
        }
    }

    var currentRole: UserRole {
        session?.user.role ?? .employee
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var queuedSubmissionCount: Int {
        queueStore.items.count
    }

    var isNetworkReachable: Bool {
        apiClient.isNetworkReachable
    }

    func bootstrap() async {
        guard session != nil else { return }
        await refreshData()
        await syncQueuedSubmissions()
    }

    func signIn(email: String, password: String) async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty, !normalizedPassword.isEmpty else {
            presentAlert("Введите почту и пароль.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await apiClient.signIn(
                request: SignInRequest(email: normalizedEmail, password: normalizedPassword)
            )
            setSession(session)
            await refreshData()
            await syncQueuedSubmissions()
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    func runDemoFlow(for role: UserRole) async {
        switchAPIClient(to: demoAPIClient)
        defaults.set(true, forKey: Self.demoModeKey)
        selectedEmployeeTab = .home
        selectedManagerTab = .team

        let email: String
        switch role {
        case .manager:
            email = "manager@demo.team"
        default:
            email = "employee@demo.team"
        }

        await signIn(email: email, password: "demo123")
    }

    func acceptInvitation(code: String, fullName: String) async {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedCode.isEmpty, !normalizedName.isEmpty else {
            presentAlert("Введите код приглашения и полное имя.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await apiClient.acceptInvitation(code: normalizedCode, fullName: normalizedName)
            setSession(session)
            pendingInviteCode = normalizedCode
            await refreshData()
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    func signOut() {
        session = nil
        employeeDashboard = nil
        managerDashboard = nil
        notifications = []
        selectedEmployeeTab = .home
        selectedManagerTab = .team
        presentedEmployee = nil
        defaults.removeObject(forKey: sessionKey)
        defaults.removeObject(forKey: Self.demoModeKey)
        keychainStore.delete(accessTokenKey)
        keychainStore.delete(refreshTokenKey)
        switchAPIClient(to: primaryAPIClient)
        apiClient.authTokens = nil
    }

    func refreshData() async {
        guard let session else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            notifications = try await apiClient.fetchNotifications()

            switch session.user.role {
            case .manager:
                managerDashboard = try await loadManagerDashboard(for: session.user)
                if let presentedEmployee {
                    self.presentedEmployee = managerDashboard?.employees.first(where: { $0.id == presentedEmployee.id })
                }
            case .employee:
                employeeDashboard = try await loadEmployeeDashboard(for: session.user)
            default:
                employeeDashboard = try await loadEmployeeDashboard(for: session.user)
            }
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    func submitDisc(dominance: Double, influence: Double, steadiness: Double, compliance: Double) async {
        guard let session else { return }

        let request = DiscSubmissionRequest(
            employeeID: session.user.id,
            answers: [
                "dominance": .number(dominance.rounded()),
                "influence": .number(influence.rounded()),
                "steadiness": .number(steadiness.rounded()),
                "compliance": .number(compliance.rounded())
            ]
        )

        await submitWithRetry(kind: .disc, employeeID: session.user.id, discRequest: request, motivationRequest: nil, pulseRequest: nil) {
            _ = try await apiClient.submitDisc(request: request)
        }
    }

    func submitMotivation(growth: Double, autonomy: Double, stability: Double, reward: Double) async {
        guard let session else { return }

        let request = MotivationSubmissionRequest(
            employeeID: session.user.id,
            answers: [
                "growth": .number(growth.rounded()),
                "autonomy": .number(autonomy.rounded()),
                "stability": .number(stability.rounded()),
                "reward": .number(reward.rounded())
            ]
        )

        await submitWithRetry(kind: .motivation, employeeID: session.user.id, discRequest: nil, motivationRequest: request, pulseRequest: nil) {
            _ = try await apiClient.submitMotivation(request: request)
        }
    }

    func submitPulse(mood: Double, stress: Double, workload: Double, recognition: Double, collaboration: Double, leaveIntent: Double) async {
        guard let session else { return }

        let request = PulseSubmissionRequest(
            mood: Int(mood.rounded()),
            stress: Int(stress.rounded()),
            workload: Int(workload.rounded()),
            recognition: Int(recognition.rounded()),
            relationships: Int(collaboration.rounded()),
            intentToLeave: Int(leaveIntent.rounded())
        )

        await submitWithRetry(kind: .pulse, employeeID: session.user.id, discRequest: nil, motivationRequest: nil, pulseRequest: request) {
            _ = try await apiClient.submitPulse(request: request)
        }
    }

    func updateProfile(jobTitle: String, department: String, workStyle: String, growthFocus: String) async -> Bool {
        guard let session else { return false }

        let request = EmployeeProfileUpdateRequest(
            profile: [
                "job_title": .string(jobTitle),
                "department": .string(department),
                "work_style": .string(workStyle),
                "growth_focus": .string(growthFocus)
            ]
        )

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await apiClient.updateEmployeeProfile(employeeID: session.user.id, request: request)
            await refreshData()
            return true
        } catch {
            presentAlert(error.localizedDescription)
            return false
        }
    }

    func markNotificationRead(_ notification: AppNotification) async {
        do {
            try await apiClient.markNotificationRead(notificationID: notification.id)
            notifications = notifications.map { current in
                guard current.id == notification.id else { return current }
                var updated = current
                updated.isRead = true
                return updated
            }
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    func setNetworkReachable(_ value: Bool) async {
        apiClient.isNetworkReachable = value
        if value {
            await syncQueuedSubmissions()
            await refreshData()
        }
    }

    func syncQueuedSubmissions() async {
        guard apiClient.isNetworkReachable, !queueStore.items.isEmpty else { return }

        isSyncingQueue = true
        defer { isSyncingQueue = false }

        for item in queueStore.items {
            do {
                switch item.kind {
                case .disc:
                    if let request = item.discRequest {
                        _ = try await apiClient.submitDisc(request: request)
                    }
                case .motivation:
                    if let request = item.motivationRequest {
                        _ = try await apiClient.submitMotivation(request: request)
                    }
                case .pulse:
                    if let request = item.pulseRequest {
                        _ = try await apiClient.submitPulse(request: request)
                    }
                }
                queueStore.remove(item)
            } catch {
                break
            }
        }

        await refreshData()
    }

    func handleURL(_ url: URL) async {
        guard let deepLink = DeepLink(url: url) else {
            presentAlert("Неподдерживаемая deeplink-ссылка.")
            return
        }

        switch deepLink.destination {
        case .employeeHome:
            selectedEmployeeTab = .home
        case .employeeAssessments:
            selectedEmployeeTab = .assessments
        case .employeePulse:
            selectedEmployeeTab = .pulse
        case .notifications:
            if currentRole == .manager {
                selectedManagerTab = .notifications
            } else {
                selectedEmployeeTab = .notifications
            }
        case .managerTeam:
            selectedManagerTab = .team
        case .managerRisks:
            selectedManagerTab = .risks
        case .employeeDetail(let employeeID):
            selectedManagerTab = .team
            if let employee = managerDashboard?.employees.first(where: { $0.id == employeeID }) {
                presentedEmployee = employee
            }
        }
    }

    func handleNotificationPayload(_ payload: [AnyHashable: Any]) async {
        if
            let destination = payload["destination"] as? String,
            let url = URL(string: "teambuilder://\(destination)")
        {
            await handleURL(url)
        }
    }

    private func loadEmployeeDashboard(for user: AppUser) async throws -> EmployeeDashboardData {
        async let profile = apiClient.fetchEmployeeProfile(employeeID: user.id)
        async let disc = apiClient.fetchLatestDisc(employeeID: user.id)
        async let motivation = apiClient.fetchLatestMotivation(employeeID: user.id)
        async let pulse = apiClient.fetchLatestPulse()

        let resolvedProfile = try await profile
        let resolvedDisc = try await disc
        let resolvedMotivation = try await motivation
        let resolvedPulse = try await pulse

        return EmployeeDashboardData(
            profile: resolvedProfile,
            disc: resolvedDisc,
            motivation: resolvedMotivation,
            latestPulse: resolvedPulse
        )
    }

    private func loadManagerDashboard(for user: AppUser) async throws -> ManagerDashboardData {
        let teamID = try await resolveManagerTeamID(from: user)

        async let analytics = apiClient.fetchTeamAnalytics(teamID: teamID)
        async let teamFallback = apiClient.fetchTeam(teamID: teamID)
        async let risks = apiClient.fetchTeamRisks(teamID: teamID)
        async let roleMap = apiClient.fetchTeamRoleMap(teamID: teamID)
        async let pulseSummary = apiClient.fetchTeamPulseSummary(teamID: teamID)

        let summary = try await analytics
        let fallbackTeam = try await teamFallback
        let mergedSummary = TeamDashboardResponse(
            teamID: summary.teamID,
            teamName: summary.teamName.isEmpty ? (fallbackTeam?.teamName ?? "Команда") : summary.teamName,
            chemistryScore: summary.chemistryScore ?? fallbackTeam?.chemistryScore,
            conflictRisk: summary.conflictRisk ?? fallbackTeam?.conflictRisk,
            attritionRisk: summary.attritionRisk ?? fallbackTeam?.attritionRisk,
            talentPoolScore: summary.talentPoolScore ?? fallbackTeam?.talentPoolScore,
            successionScore: summary.successionScore ?? fallbackTeam?.successionScore
        )

        let employees = mergeEmployees(primary: try await roleMap, secondary: try await pulseSummary)

        return ManagerDashboardData(
            summary: mergedSummary,
            risks: try await risks,
            employees: employees
        )
    }

    private func resolveManagerTeamID(from user: AppUser) async throws -> UUID {
        if let teamID = user.teamID {
            return teamID
        }

        let teams = try await apiClient.fetchTeams()
        guard let teamID = teams.first?.teamID else {
            throw APIClientError.invalidState("Для пользователя не найдена команда.")
        }
        return teamID
    }

    private func mergeEmployees(primary: [EmployeeSnapshot], secondary: [EmployeeSnapshot]) -> [EmployeeSnapshot] {
        var storage = Dictionary(uniqueKeysWithValues: primary.map { ($0.id, $0) })

        for employee in secondary {
            if let current = storage[employee.id] {
                storage[employee.id] = EmployeeSnapshot(
                    id: current.id,
                    fullName: current.fullName.isEmpty ? employee.fullName : current.fullName,
                    roleTitle: current.roleTitle.isEmpty ? employee.roleTitle : current.roleTitle,
                    chemistryFit: current.chemistryFit ?? employee.chemistryFit,
                    burnoutRisk: current.burnoutRisk ?? employee.burnoutRisk,
                    potential: current.potential ?? employee.potential,
                    summary: current.summary ?? employee.summary
                )
            } else {
                storage[employee.id] = employee
            }
        }

        return storage.values.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    private func submitWithRetry(
        kind: SubmissionKind,
        employeeID: UUID,
        discRequest: DiscSubmissionRequest?,
        motivationRequest: MotivationSubmissionRequest?,
        pulseRequest: PulseSubmissionRequest?,
        action: () async throws -> Void
    ) async {
        do {
            try await action()
            await refreshData()
        } catch {
            if case APIClientError.networkUnavailable = error {
                let queuedItem = QueuedSubmission(
                    id: UUID(),
                    kind: kind,
                    employeeID: employeeID,
                    discRequest: discRequest,
                    motivationRequest: motivationRequest,
                    pulseRequest: pulseRequest,
                    createdAt: Date()
                )
                queueStore.append(queuedItem)
                presentAlert("Сохранено офлайн. Данные синхронизируются автоматически.")
            } else {
                presentAlert(error.localizedDescription)
            }
        }
    }

    private func setSession(_ session: UserSession) {
        self.session = session
        apiClient.authTokens = session.tokens

        if let data = try? JSONEncoder().encode(session.user) {
            defaults.set(data, forKey: sessionKey)
        }

        persistTokens(session.tokens)
    }

    private func configureAPIClient(_ client: any APIClient & NetworkStateControlling) {
        client.authTokens = session?.tokens
        client.onTokenRefresh = { [weak self] tokens in
            Task { @MainActor in
                self?.persistTokens(tokens)
            }
        }
    }

    private func switchAPIClient(to client: any APIClient & NetworkStateControlling) {
        apiClient = client
        configureAPIClient(client)
    }

    private func persistTokens(_ tokens: SessionTokens) {
        keychainStore.save(tokens.accessToken, account: accessTokenKey)
        keychainStore.save(tokens.refreshToken, account: refreshTokenKey)

        if let current = session {
            session = UserSession(user: current.user, tokens: tokens)
        }

        apiClient.authTokens = tokens
    }

    private func presentAlert(_ message: String) {
        alertMessage = message
        isAlertPresented = true
    }

    private static func loadSession(
        defaults: UserDefaults,
        keychainStore: KeychainStore,
        sessionKey: String,
        accessTokenKey: String,
        refreshTokenKey: String
    ) -> UserSession? {
        guard
            let data = defaults.data(forKey: sessionKey),
            let user = try? JSONDecoder().decode(AppUser.self, from: data),
            let accessToken = keychainStore.read(account: accessTokenKey),
            let refreshToken = keychainStore.read(account: refreshTokenKey)
        else {
            return nil
        }

        return UserSession(
            user: user,
            tokens: SessionTokens(accessToken: accessToken, refreshToken: refreshToken)
        )
    }
}
