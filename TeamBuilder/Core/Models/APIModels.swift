//
//  APIModels.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

struct ResponseEnvelope<DataType: Codable>: Codable {
    let success: Bool
    let data: DataType?
    let error: APIErrorPayload?
    let meta: MetaPayload
}

struct APIErrorPayload: Codable {
    let code: String
    let message: String
    let details: [String]
}

struct MetaPayload: Codable {
    let requestID: UUID
    let timestamp: Date
    let page: Int?
    let pageSize: Int?
    let total: Int?
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct InvitationAcceptRequest: Codable {
    let code: String
    let fullName: String
}

struct EmployeeProfileUpdateRequest: Codable {
    let jobTitle: String
    let department: String
    let workStyle: String
    let growthFocus: String
}

struct DiscSubmissionRequest: Codable {
    let employeeID: UUID
    let dominance: Int
    let influence: Int
    let steadiness: Int
    let compliance: Int
    let submittedAt: Date
}

struct MotivationSubmissionRequest: Codable {
    let employeeID: UUID
    let growth: Int
    let autonomy: Int
    let stability: Int
    let reward: Int
    let submittedAt: Date
}

struct PulseSubmissionRequest: Codable {
    let employeeID: UUID
    let mood: Int
    let stress: Int
    let workload: Int
    let recognition: Int
    let collaboration: Int
    let leaveIntent: Int
    let submittedAt: Date
}

struct UserSessionDTO: Codable {
    let user: AppUser
    let accessToken: String
    let refreshToken: String

    func toDomainSession() -> UserSession {
        UserSession(
            user: user,
            tokens: SessionTokens(accessToken: accessToken, refreshToken: refreshToken)
        )
    }
}
