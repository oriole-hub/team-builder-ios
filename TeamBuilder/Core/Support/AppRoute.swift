//
//  AppRoute.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

enum EmployeeTab: Hashable {
    case home
    case assessments
    case pulse
    case notifications
    case profile
}

enum ManagerTab: Hashable {
    case team
    case risks
    case notifications
    case profile
}

enum DeepLinkDestination: Hashable {
    case employeeHome
    case employeeAssessments
    case employeePulse
    case notifications
    case managerTeam
    case managerRisks
    case employeeDetail(UUID)
}

struct DeepLink: Hashable {
    let destination: DeepLinkDestination

    init?(url: URL) {
        let host = url.host ?? ""
        let components = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "home":
            destination = .employeeHome
        case "assessments":
            destination = .employeeAssessments
        case "pulse":
            destination = .employeePulse
        case "notifications":
            destination = .notifications
        case "summary":
            destination = .managerTeam
        case "team":
            if
                components.count == 2,
                components.first == "employee",
                let employeeID = UUID(uuidString: components[1])
            {
                destination = .employeeDetail(employeeID)
            } else {
                destination = .managerTeam
            }
        case "risks":
            destination = .managerRisks
        default:
            return nil
        }
    }
}
