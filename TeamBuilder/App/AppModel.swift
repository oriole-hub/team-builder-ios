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
    @Published private(set) var session: UserSession?
    @Published private(set) var employeeDashboard: EmployeeDashboardData?
    @Published private(set) var managerDashboard: ManagerDashboardData?
    @Published private(set) var notifications: [AppNotification] = []
    @Published var selectedEmployeeTab: EmployeeTab = .home
    @Published var selectedManagerTab: ManagerTab = .summary
    @Published var isAlertPresented = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    @Published var isSyncingQueue = false
    @Published var presentedEmployee: EmployeeSnapshot?
    @Published var pendingInviteCode = ""

    private let apiClient: any APIClient & NetworkStateControlling
    private let keychainStore = KeychainStore()
    private let queueStore = OfflineQueueStore()
    private let defaults = UserDefaults.standard

    private let sessionKey = "team_builder.session"
    private let accessTokenKey = "team_builder.access_token"
    private let refreshTokenKey = "team_builder.refresh_token"

    init(apiClient: some APIClient & NetworkStateControlling) {
        self.apiClient = apiClient
        self.session = Self.loadSession(
            defaults: defaults,
            keychainStore: keychainStore,
            sessionKey: sessionKey,
            accessTokenKey: accessTokenKey,
            refreshTokenKey: refreshTokenKey
        )
    }

    convenience init() {
        self.init(apiClient: MockAPIClient())
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
            let response = try await apiClient.signIn(
                request: SignInRequest(email: normalizedEmail, password: normalizedPassword)
            )
            guard let session = response.data?.toDomainSession() else {
                presentAlert("Не удалось получить данные сессии.")
                return
            }
            setSession(session)
            await refreshData()
            await syncQueuedSubmissions()
        } catch {
            presentAlert(error.localizedDescription)
        }
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
            let response = try await apiClient.acceptInvitation(
                code: normalizedCode,
                fullName: normalizedName
            )
            guard let session = response.data?.toDomainSession() else {
                presentAlert("Ответ по приглашению неполный.")
                return
            }
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
        selectedManagerTab = .summary
        presentedEmployee = nil
        defaults.removeObject(forKey: sessionKey)
        keychainStore.delete(accessTokenKey)
        keychainStore.delete(refreshTokenKey)
    }

    func refreshData() async {
        guard let session else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let notificationsResponse = try await apiClient.fetchNotifications(userID: session.user.id)
            notifications = notificationsResponse.data ?? []

            switch session.user.role {
            case .manager:
                let response = try await apiClient.fetchManagerDashboard(userID: session.user.id)
                managerDashboard = response.data
                if let presentedEmployee {
                    self.presentedEmployee = response.data?.employees.first(where: { $0.id == presentedEmployee.id })
                }
            case .employee:
                let response = try await apiClient.fetchEmployeeDashboard(userID: session.user.id)
                employeeDashboard = response.data
            default:
                break
            }
        } catch {
            presentAlert(error.localizedDescription)
        }
    }

    func submitDisc(dominance: Double, influence: Double, steadiness: Double, compliance: Double) async {
        guard let session else { return }

        let request = DiscSubmissionRequest(
            employeeID: session.user.id,
            dominance: Int(dominance),
            influence: Int(influence),
            steadiness: Int(steadiness),
            compliance: Int(compliance),
            submittedAt: Date()
        )

        await submitWithRetry(kind: .disc, employeeID: session.user.id, discRequest: request, motivationRequest: nil, pulseRequest: nil) {
            _ = try await apiClient.submitDisc(request: request)
        }
    }

    func submitMotivation(growth: Double, autonomy: Double, stability: Double, reward: Double) async {
        guard let session else { return }

        let request = MotivationSubmissionRequest(
            employeeID: session.user.id,
            growth: Int(growth),
            autonomy: Int(autonomy),
            stability: Int(stability),
            reward: Int(reward),
            submittedAt: Date()
        )

        await submitWithRetry(kind: .motivation, employeeID: session.user.id, discRequest: nil, motivationRequest: request, pulseRequest: nil) {
            _ = try await apiClient.submitMotivation(request: request)
        }
    }

    func submitPulse(mood: Double, stress: Double, workload: Double, recognition: Double, collaboration: Double, leaveIntent: Double) async {
        guard let session else { return }

        let request = PulseSubmissionRequest(
            employeeID: session.user.id,
            mood: Int(mood),
            stress: Int(stress),
            workload: Int(workload),
            recognition: Int(recognition),
            collaboration: Int(collaboration),
            leaveIntent: Int(leaveIntent),
            submittedAt: Date()
        )

        await submitWithRetry(kind: .pulse, employeeID: session.user.id, discRequest: nil, motivationRequest: nil, pulseRequest: request) {
            _ = try await apiClient.submitPulse(request: request)
        }
    }

    func updateProfile(jobTitle: String, department: String, workStyle: String, growthFocus: String) async -> Bool {
        guard let session else { return false }

        let request = EmployeeProfileUpdateRequest(
            jobTitle: jobTitle,
            department: department,
            workStyle: workStyle,
            growthFocus: growthFocus
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
            _ = try await apiClient.markNotificationRead(notificationID: notification.id)
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
        case .managerSummary:
            selectedManagerTab = .summary
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

        if let data = try? JSONEncoder().encode(session.user) {
            defaults.set(data, forKey: sessionKey)
        }

        keychainStore.save(session.tokens.accessToken, account: accessTokenKey)
        keychainStore.save(session.tokens.refreshToken, account: refreshTokenKey)
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
