//
//  DomainModels.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case companyAdmin = "company_admin"
    case hr
    case manager
    case employee

    var id: String { rawValue }
}

struct SessionTokens: Hashable {
    let accessToken: String
    let refreshToken: String
}

struct UserSession: Hashable {
    let user: AppUser
    let tokens: SessionTokens
}

struct AppUser: Identifiable, Codable, Hashable {
    let id: UUID
    let fullName: String
    let email: String
    let role: UserRole
    let companyID: UUID?
    let teamID: UUID?
}

struct DiscResult: Codable, Hashable {
    let dominance: Int
    let influence: Int
    let steadiness: Int
    let compliance: Int

    var dominantStyle: String {
        let pairs = [
            ("D", dominance),
            ("I", influence),
            ("S", steadiness),
            ("C", compliance)
        ]
        return pairs.max(by: { $0.1 < $1.1 })?.0 ?? "D"
    }
}

struct MotivationResult: Codable, Hashable {
    let growth: Int
    let autonomy: Int
    let stability: Int
    let reward: Int
}

struct PulseEntry: Codable, Hashable {
    let mood: Int
    let stress: Int
    let workload: Int
    let recognition: Int
    let collaboration: Int
    let leaveIntent: Int
    let submittedAt: Date
}

struct EmployeeProfileData: Codable, Hashable {
    let fullName: String
    let jobTitle: String
    let department: String
    let workStyle: String
    let growthFocus: String
    let tenure: String
    let workMode: String
}

struct EmployeeDashboardData: Codable, Hashable {
    let profile: EmployeeProfileData
    let disc: DiscResult?
    let motivation: MotivationResult?
    let latestPulse: PulseEntry?
}

struct TeamRiskItem: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let severity: String
    let message: String
}

struct TeamDashboardResponse: Codable, Hashable {
    let teamID: UUID
    let teamName: String
    let chemistryScore: Int?
    let conflictRisk: Int?
    let attritionRisk: Int?
    let talentPoolScore: Int?
    let successionScore: Int?
}

struct EmployeeSnapshot: Identifiable, Codable, Hashable {
    let id: UUID
    let fullName: String
    let roleTitle: String
    let chemistryFit: Int?
    let burnoutRisk: Int?
    let potential: Int?
    let summary: String?
}

struct ManagerDashboardData: Codable, Hashable {
    let summary: TeamDashboardResponse
    let risks: [TeamRiskItem]
    let employees: [EmployeeSnapshot]
}

struct AppNotification: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool
    let deepLink: String?
}
