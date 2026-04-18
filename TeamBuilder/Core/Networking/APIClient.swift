//
//  APIClient.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

enum APIEndpoint {
    case signIn
    case acceptInvitation
    case me
    case employeeProfile(UUID)
    case discSubmission
    case motivationSubmission
    case pulseSubmission
    case teamDashboard(UUID)
    case teamRisks(UUID)
    case notifications
    case notificationRead(UUID)

    var method: HTTPMethod {
        switch self {
        case .me, .teamDashboard, .teamRisks, .notifications:
            return .get
        case .employeeProfile:
            return .patch
        case .notificationRead, .signIn, .acceptInvitation, .discSubmission, .motivationSubmission, .pulseSubmission:
            return .post
        }
    }

    var path: String {
        switch self {
        case .signIn:
            return "/v1/auth/signin"
        case .acceptInvitation:
            return "/v1/invitations/accept"
        case .me:
            return "/v1/me"
        case .employeeProfile(let employeeID):
            return "/v1/employees/\(employeeID.uuidString.lowercased())/profile"
        case .discSubmission:
            return "/v1/assessments/disc/submissions"
        case .motivationSubmission:
            return "/v1/assessments/motivation/submissions"
        case .pulseSubmission:
            return "/v1/pulse/submissions"
        case .teamDashboard(let teamID):
            return "/v1/analytics/teams/\(teamID.uuidString.lowercased())/dashboard"
        case .teamRisks(let teamID):
            return "/v1/analytics/teams/\(teamID.uuidString.lowercased())/risks"
        case .notifications:
            return "/v1/notifications"
        case .notificationRead(let notificationID):
            return "/v1/notifications/\(notificationID.uuidString.lowercased())/read"
        }
    }
}

enum APIClientError: LocalizedError {
    case networkUnavailable
    case unauthorized
    case notFound
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Сеть недоступна."
        case .unauthorized:
            return "Ошибка аутентификации."
        case .notFound:
            return "Запрошенные данные не найдены."
        case .invalidState(let message):
            return message
        }
    }
}

protocol NetworkStateControlling: AnyObject {
    var isNetworkReachable: Bool { get set }
}

protocol APIClient: AnyObject {
    func signIn(request: SignInRequest) async throws -> ResponseEnvelope<UserSessionDTO>
    func acceptInvitation(code: String, fullName: String) async throws -> ResponseEnvelope<UserSessionDTO>
    func fetchEmployeeDashboard(userID: UUID) async throws -> ResponseEnvelope<EmployeeDashboardData>
    func fetchManagerDashboard(userID: UUID) async throws -> ResponseEnvelope<ManagerDashboardData>
    func fetchNotifications(userID: UUID) async throws -> ResponseEnvelope<[AppNotification]>
    func submitDisc(request: DiscSubmissionRequest) async throws -> ResponseEnvelope<DiscResult>
    func submitMotivation(request: MotivationSubmissionRequest) async throws -> ResponseEnvelope<MotivationResult>
    func submitPulse(request: PulseSubmissionRequest) async throws -> ResponseEnvelope<PulseEntry>
    func updateEmployeeProfile(employeeID: UUID, request: EmployeeProfileUpdateRequest) async throws -> ResponseEnvelope<EmployeeProfileData>
    func markNotificationRead(notificationID: UUID) async throws -> ResponseEnvelope<AppNotification>
}
