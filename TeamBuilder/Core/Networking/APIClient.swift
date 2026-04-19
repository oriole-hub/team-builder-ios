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

enum APIClientError: LocalizedError {
    case networkUnavailable
    case unauthorized
    case notFound
    case invalidResponse
    case serverError(String)
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Сеть недоступна."
        case .unauthorized:
            return "Ошибка аутентификации."
        case .notFound:
            return "Запрошенные данные не найдены."
        case .invalidResponse:
            return "Сервер вернул непонятный ответ."
        case .serverError(let message):
            return message
        case .invalidState(let message):
            return message
        }
    }
}

protocol NetworkStateControlling: AnyObject {
    var isNetworkReachable: Bool { get set }
}

protocol APIClient: AnyObject {
    var authTokens: SessionTokens? { get set }
    var onTokenRefresh: ((SessionTokens) -> Void)? { get set }

    func signIn(request: SignInRequest) async throws -> UserSession
    func acceptInvitation(code: String, fullName: String) async throws -> UserSession
    func fetchCurrentUser() async throws -> AppUser
    func fetchNotifications() async throws -> [AppNotification]
    func fetchEmployeeProfile(employeeID: UUID) async throws -> EmployeeProfileData
    func fetchLatestDisc(employeeID: UUID) async throws -> DiscResult?
    func fetchLatestMotivation(employeeID: UUID) async throws -> MotivationResult?
    func fetchLatestPulse() async throws -> PulseEntry?
    func submitDisc(request: DiscSubmissionRequest) async throws -> DiscResult?
    func submitMotivation(request: MotivationSubmissionRequest) async throws -> MotivationResult?
    func submitPulse(request: PulseSubmissionRequest) async throws -> PulseEntry?
    func updateEmployeeProfile(employeeID: UUID, request: EmployeeProfileUpdateRequest) async throws -> EmployeeProfileData
    func fetchTeams() async throws -> [TeamDashboardResponse]
    func fetchTeam(teamID: UUID) async throws -> TeamDashboardResponse?
    func fetchTeamPulseSummary(teamID: UUID) async throws -> [EmployeeSnapshot]
    func fetchTeamAnalytics(teamID: UUID) async throws -> TeamDashboardResponse
    func fetchTeamRisks(teamID: UUID) async throws -> [TeamRiskItem]
    func fetchTeamRoleMap(teamID: UUID) async throws -> [EmployeeSnapshot]
    func markNotificationRead(notificationID: UUID) async throws
}

final class LiveAPIClient: APIClient, NetworkStateControlling {
    var isNetworkReachable = true
    var authTokens: SessionTokens?
    var onTokenRefresh: ((SessionTokens) -> Void)?

    private let baseURL = URL(string: "https://convulsively-central-greyhound.cloudpub.ru/")!
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signIn(request: SignInRequest) async throws -> UserSession {
        let payload = try await requestJSON(path: "/v1/auth/signin", method: .post, body: request, includeAuth: false)
        let tokens = try extractTokens(from: payload)
        authTokens = tokens
        onTokenRefresh?(tokens)
        let user = try await fetchCurrentUser()
        return UserSession(user: user, tokens: tokens)
    }

    func acceptInvitation(code: String, fullName: String) async throws -> UserSession {
        let request = InvitationAcceptRequest(token: code, password: UUID().uuidString, fullName: fullName)
        let payload = try await requestJSON(path: "/v1/invitations/accept", method: .post, body: request, includeAuth: false)
        let tokens = try extractTokens(from: payload)
        authTokens = tokens
        onTokenRefresh?(tokens)
        let user = try await fetchCurrentUser()
        return UserSession(user: user, tokens: tokens)
    }

    func fetchCurrentUser() async throws -> AppUser {
        let payload = try await authorizedJSON(path: "/v1/me", method: .get)
        return try parseUser(from: payload)
    }

    func fetchNotifications() async throws -> [AppNotification] {
        let payload = try await authorizedJSON(path: "/v1/notify", method: .get)
        return parseNotifications(from: payload)
    }

    func fetchEmployeeProfile(employeeID: UUID) async throws -> EmployeeProfileData {
        let payload = try await authorizedJSON(path: "/v1/employe/\(employeeID.uuidString.lowercased())", method: .get)
        return try parseEmployeeProfile(from: payload)
    }

    func fetchLatestDisc(employeeID: UUID) async throws -> DiscResult? {
        let payload = try await authorizedJSON(path: "/v1/employee/\(employeeID.uuidString.lowercased())/ocenka/latest", method: .get)
        return parseDisc(from: payload)
    }

    func fetchLatestMotivation(employeeID: UUID) async throws -> MotivationResult? {
        let payload = try await authorizedJSON(path: "/v1/employee/\(employeeID.uuidString.lowercased())/ocenka/motiv/latest", method: .get)
        return parseMotivation(from: payload)
    }

    func fetchLatestPulse() async throws -> PulseEntry? {
        let payload = try await authorizedJSON(path: "/v1/pulse/my/latest", method: .get)
        return parsePulse(from: payload)
    }

    func submitDisc(request: DiscSubmissionRequest) async throws -> DiscResult? {
        let payload = try await authorizedJSON(path: "/v1/assessments/disc/submissions", method: .post, body: request)
        return parseDisc(from: payload)
    }

    func submitMotivation(request: MotivationSubmissionRequest) async throws -> MotivationResult? {
        let payload = try await authorizedJSON(path: "/v1/ocenka/motiv/opros", method: .post, body: request)
        return parseMotivation(from: payload)
    }

    func submitPulse(request: PulseSubmissionRequest) async throws -> PulseEntry? {
        let payload = try await authorizedJSON(path: "/v1/pulse/opros", method: .post, body: request)
        return parsePulse(from: payload)
    }

    func updateEmployeeProfile(employeeID: UUID, request: EmployeeProfileUpdateRequest) async throws -> EmployeeProfileData {
        let payload = try await authorizedJSON(path: "/v1/employe/\(employeeID.uuidString.lowercased())/profile", method: .patch, body: request)
        return try parseEmployeeProfile(from: payload)
    }

    func fetchTeams() async throws -> [TeamDashboardResponse] {
        let payload = try await authorizedJSON(path: "/v1/teams", method: .get)
        return parseTeams(from: payload)
    }

    func fetchTeam(teamID: UUID) async throws -> TeamDashboardResponse? {
        let payload = try await authorizedJSON(path: "/v1/teams/\(teamID.uuidString.lowercased())", method: .get)
        return parseTeam(from: payload)
    }

    func fetchTeamPulseSummary(teamID: UUID) async throws -> [EmployeeSnapshot] {
        let payload = try await authorizedJSON(path: "/v1/teams/\(teamID.uuidString.lowercased())/pulse/summary", method: .get)
        return parseEmployeeSnapshots(from: payload)
    }

    func fetchTeamAnalytics(teamID: UUID) async throws -> TeamDashboardResponse {
        let payload = try await authorizedJSON(path: "/v1/analytics/teams/\(teamID.uuidString.lowercased())/dashboard", method: .get)
        if let team = parseTeam(from: payload) {
            return team
        }
        throw APIClientError.invalidResponse
    }

    func fetchTeamRisks(teamID: UUID) async throws -> [TeamRiskItem] {
        let payload = try await authorizedJSON(path: "/v1/analytics/teams/\(teamID.uuidString.lowercased())/risks", method: .get)
        return parseRisks(from: payload)
    }

    func fetchTeamRoleMap(teamID: UUID) async throws -> [EmployeeSnapshot] {
        let payload = try await authorizedJSON(path: "/v1/analytics/teams/\(teamID.uuidString.lowercased())/role-map", method: .get)
        return parseEmployeeSnapshots(from: payload)
    }

    func markNotificationRead(notificationID: UUID) async throws {
        _ = try await authorizedJSON(path: "/v1/notify/\(notificationID.uuidString.lowercased())/read", method: .post)
    }

    private func authorizedJSON<Body: Encodable>(path: String, method: HTTPMethod, body: Body? = nil) async throws -> JSONValue {
        do {
            return try await requestJSON(path: path, method: method, body: body, includeAuth: true)
        } catch APIClientError.unauthorized {
            try await refreshTokens()
            return try await requestJSON(path: path, method: method, body: body, includeAuth: true)
        }
    }

    private func authorizedJSON(path: String, method: HTTPMethod) async throws -> JSONValue {
        try await authorizedJSON(path: path, method: method, body: Optional<EmptyBody>.none)
    }

    private func refreshTokens() async throws {
        guard let refreshToken = authTokens?.refreshToken else {
            throw APIClientError.unauthorized
        }

        let payload = try await requestJSON(
            path: "/v1/auth/refresh",
            method: .post,
            body: RefreshRequest(refreshToken: refreshToken),
            includeAuth: false
        )
        let tokens = try extractTokens(from: payload)
        authTokens = tokens
        onTokenRefresh?(tokens)
    }

    private func requestJSON<Body: Encodable>(
        path: String,
        method: HTTPMethod,
        body: Body? = nil,
        includeAuth: Bool
    ) async throws -> JSONValue {
        guard isNetworkReachable else {
            throw APIClientError.networkUnavailable
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if includeAuth, let accessToken = authTokens?.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200..<300:
                if data.isEmpty {
                    return .null
                }
                return try decoder.decode(JSONValue.self, from: data)
            case 401:
                throw APIClientError.unauthorized
            case 404:
                throw APIClientError.notFound
            default:
                throw decodeServerError(data: data, statusCode: httpResponse.statusCode)
            }
        } catch let error as APIClientError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .cannotFindHost || error.code == .cannotConnectToHost || error.code == .networkConnectionLost {
                throw APIClientError.networkUnavailable
            }
            throw APIClientError.serverError(error.localizedDescription)
        } catch {
            throw APIClientError.serverError(error.localizedDescription)
        }
    }

    private func decodeServerError(data: Data, statusCode: Int) -> APIClientError {
        if
            let json = try? decoder.decode(JSONValue.self, from: data),
            let object = json.objectValue
        {
            let message = object.string(for: "detail", "message", "error_description", "error")
            if let message, !message.isEmpty {
                return statusCode == 401 ? .unauthorized : .serverError(message)
            }
        }

        if let html = String(data: data, encoding: .utf8), !html.isEmpty {
            if statusCode == 503 {
                return .serverError("Бэкенд сейчас недоступен (503).")
            }
        }

        return .serverError("Ошибка сервера (\(statusCode)).")
    }
}

private struct EmptyBody: Encodable {}

private extension LiveAPIClient {
    func extractTokens(from payload: JSONValue) throws -> SessionTokens {
        let object = rootObject(from: payload)
        guard
            let accessToken = object.string(for: "access_token", "accessToken", "token"),
            let refreshToken = object.string(for: "refresh_token", "refreshToken")
        else {
            throw APIClientError.invalidResponse
        }
        return SessionTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    func parseUser(from payload: JSONValue) throws -> AppUser {
        let object = rootObject(from: payload)
        let userObject = object.object(for: "user", "me") ?? object

        guard
            let id = userObject.uuid(for: "id", "user_id"),
            let fullName = userObject.string(for: "full_name", "fullName", "name"),
            let email = userObject.string(for: "email"),
            let roleString = userObject.string(for: "role", "user_role"),
            let role = UserRole(rawValue: roleString)
        else {
            throw APIClientError.invalidResponse
        }

        return AppUser(
            id: id,
            fullName: fullName,
            email: email,
            role: role,
            companyID: userObject.uuid(for: "company_id", "companyId"),
            teamID: userObject.uuid(for: "team_id", "teamId")
        )
    }

    func parseEmployeeProfile(from payload: JSONValue) throws -> EmployeeProfileData {
        let object = rootObject(from: payload)
        let profile = object.object(for: "profile") ?? [:]

        let fullName = object.string(for: "full_name", "fullName", "name")
            ?? profile.string(for: "full_name", "fullName", "name")
            ?? "Сотрудник"
        let jobTitle = object.string(for: "job_title", "jobTitle", "title")
            ?? profile.string(for: "job_title", "jobTitle", "title")
            ?? ""
        let department = object.string(for: "department")
            ?? profile.string(for: "department")
            ?? ""
        let workStyle = profile.string(for: "work_style", "workStyle")
            ?? object.string(for: "work_style", "workStyle")
            ?? ""
        let growthFocus = profile.string(for: "growth_focus", "growthFocus")
            ?? object.string(for: "growth_focus", "growthFocus")
            ?? ""
        let tenure = stringifyTenure(months: object.int(for: "tenure_months", "tenureMonths"), fallback: profile.string(for: "tenure"))
        let workMode = object.string(for: "work_format", "workFormat")
            ?? profile.string(for: "work_format", "workMode", "work_format_label")
            ?? ""

        return EmployeeProfileData(
            fullName: fullName,
            jobTitle: jobTitle,
            department: department,
            workStyle: workStyle,
            growthFocus: growthFocus,
            tenure: tenure,
            workMode: workMode
        )
    }

    func parseDisc(from payload: JSONValue) -> DiscResult? {
        let object = rootObject(from: payload)
        let answers = object.object(for: "answers", "scores", "result") ?? object

        guard
            let dominance = answers.int(for: "dominance", "d"),
            let influence = answers.int(for: "influence", "i"),
            let steadiness = answers.int(for: "steadiness", "s"),
            let compliance = answers.int(for: "compliance", "c")
        else {
            return nil
        }

        return DiscResult(dominance: dominance, influence: influence, steadiness: steadiness, compliance: compliance)
    }

    func parseMotivation(from payload: JSONValue) -> MotivationResult? {
        let object = rootObject(from: payload)
        let answers = object.object(for: "answers", "scores", "result") ?? object

        guard
            let growth = answers.int(for: "growth"),
            let autonomy = answers.int(for: "autonomy"),
            let stability = answers.int(for: "stability"),
            let reward = answers.int(for: "reward")
        else {
            return nil
        }

        return MotivationResult(growth: growth, autonomy: autonomy, stability: stability, reward: reward)
    }

    func parsePulse(from payload: JSONValue) -> PulseEntry? {
        let object = rootObject(from: payload)
        let source = object.object(for: "pulse", "result", "latest") ?? object

        guard
            let mood = source.int(for: "mood"),
            let stress = source.int(for: "stress"),
            let workload = source.int(for: "workload"),
            let recognition = source.int(for: "recognition"),
            let collaboration = source.int(for: "relationships", "collaboration"),
            let leaveIntent = source.int(for: "intent_to_leave", "leave_intent", "leaveIntent")
        else {
            return nil
        }

        let submittedAt = source.value(for: ["submitted_at", "submittedAt", "created_at", "createdAt"])?.dateValue ?? Date()
        return PulseEntry(
            mood: mood,
            stress: stress,
            workload: workload,
            recognition: recognition,
            collaboration: collaboration,
            leaveIntent: leaveIntent,
            submittedAt: submittedAt
        )
    }

    func parseNotifications(from payload: JSONValue) -> [AppNotification] {
        let objects = rootArray(from: payload)
        return objects.compactMap { item in
            guard
                let id = item.uuid(for: "id", "notification_id"),
                let title = item.string(for: "title"),
                let message = item.string(for: "message", "body", "text")
            else {
                return nil
            }

            return AppNotification(
                id: id,
                title: title,
                message: message,
                createdAt: item.value(for: ["created_at", "createdAt", "timestamp"])?.dateValue ?? Date(),
                isRead: item.bool(for: "is_read", "read", "isRead") ?? false,
                deepLink: item.string(for: "deep_link", "deepLink", "link")
            )
        }
    }

    func parseTeams(from payload: JSONValue) -> [TeamDashboardResponse] {
        rootArray(from: payload).compactMap(parseTeamObject)
    }

    func parseTeam(from payload: JSONValue) -> TeamDashboardResponse? {
        parseTeamObject(rootObject(from: payload))
    }

    func parseTeamObject(_ object: [String: JSONValue]) -> TeamDashboardResponse? {
        guard
            let teamID = object.uuid(for: "id", "team_id"),
            let teamName = object.string(for: "name", "team_name", "title")
        else {
            return nil
        }

        return TeamDashboardResponse(
            teamID: teamID,
            teamName: teamName,
            chemistryScore: object.int(for: "chemistry_score", "chemistry", "score"),
            conflictRisk: object.int(for: "conflict_risk", "conflictRisk"),
            attritionRisk: object.int(for: "attrition_risk", "attritionRisk", "leave_risk"),
            talentPoolScore: object.int(for: "talent_pool_score", "talentPoolScore"),
            successionScore: object.int(for: "succession_score", "successionScore")
        )
    }

    func parseRisks(from payload: JSONValue) -> [TeamRiskItem] {
        rootArray(from: payload).compactMap { item in
            let fallbackTitle = item.string(for: "title", "name") ?? "Риск"
            let fallbackMessage = item.string(for: "message", "description", "summary") ?? ""

            return TeamRiskItem(
                id: item.uuid(for: "id", "risk_id") ?? UUID(),
                title: fallbackTitle,
                severity: item.string(for: "severity", "level") ?? "unknown",
                message: fallbackMessage
            )
        }
    }

    func parseEmployeeSnapshots(from payload: JSONValue) -> [EmployeeSnapshot] {
        rootArray(from: payload).compactMap { parseEmployeeSnapshotObject($0) }
    }

    func parseEmployeeSnapshotObject(_ object: [String: JSONValue]) -> EmployeeSnapshot? {
        let nested = object.object(for: "employee", "user") ?? [:]
        let source = nested.isEmpty ? object : nested

        guard
            let id = source.uuid(for: "id", "employee_id", "user_id"),
            let fullName = source.string(for: "full_name", "fullName", "name")
        else {
            return nil
        }

        return EmployeeSnapshot(
            id: id,
            fullName: fullName,
            roleTitle: source.string(for: "job_title", "role_title", "title", "position") ?? "",
            chemistryFit: object.int(for: "chemistry_score", "chemistryFit", "fit_score"),
            burnoutRisk: object.int(for: "burnout_risk", "burnoutRisk", "stress_risk"),
            potential: object.int(for: "potential", "potential_score", "talent_score"),
            summary: object.string(for: "summary", "recommendation", "message", "description")
        )
    }

    func rootObject(from payload: JSONValue) -> [String: JSONValue] {
        guard let object = payload.objectValue else { return [:] }

        if let dataObject = object.object(for: "data"), !dataObject.isEmpty {
            return dataObject
        }

        return object
    }

    func rootArray(from payload: JSONValue) -> [[String: JSONValue]] {
        if let dataArray = rootObject(from: payload).array(for: "items", "notifications", "results", "employees", "members", "risks", "teams") {
            return dataArray.compactMap(\.objectValue)
        }

        if let array = payload.arrayValue {
            return array.compactMap(\.objectValue)
        }

        if let data = payload.objectValue?.object(for: "data"), let items = data.array(for: "items", "notifications", "results", "employees", "members", "risks", "teams") {
            return items.compactMap(\.objectValue)
        }

        return []
    }

    func stringifyTenure(months: Int?, fallback: String?) -> String {
        if let fallback, !fallback.isEmpty {
            return fallback
        }

        guard let months else { return "" }
        let years = months / 12
        let remainingMonths = months % 12

        switch (years, remainingMonths) {
        case (0, let monthCount):
            return "\(monthCount) мес."
        case (let yearCount, 0):
            return "\(yearCount) г."
        default:
            return "\(years) г. \(remainingMonths) мес."
        }
    }
}
