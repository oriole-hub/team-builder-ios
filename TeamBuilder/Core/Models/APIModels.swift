//
//  APIModels.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

enum JSONValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

extension JSONValue {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.rounded(.towardZero) == value ? String(Int(value)) : String(value)
        case .bool(let value):
            return String(value)
        default:
            return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .number(let value):
            return value
        case .string(let value):
            return Double(value)
        default:
            return nil
        }
    }

    var intValue: Int? {
        guard let value = doubleValue else { return nil }
        return Int(value.rounded())
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let value):
            return value
        case .string(let value):
            return Bool(value)
        default:
            return nil
        }
    }

    var objectValue: [String: JSONValue]? {
        guard case .object(let value) = self else { return nil }
        return value
    }

    var arrayValue: [JSONValue]? {
        guard case .array(let value) = self else { return nil }
        return value
    }

    var uuidValue: UUID? {
        guard let stringValue else { return nil }
        return UUID(uuidString: stringValue)
    }

    var dateValue: Date? {
        guard let stringValue else { return nil }
        return APIFormats.decodeDate(stringValue)
    }
}

enum APIFormats {
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func decodeDate(_ string: String) -> Date? {
        iso8601WithFractionalSeconds.date(from: string) ?? iso8601.date(from: string)
    }
}

extension Dictionary where Key == String, Value == JSONValue {
    func value(for keys: [String]) -> JSONValue? {
        for key in keys {
            if let value = self[key] {
                return value
            }
        }
        return nil
    }

    func string(for keys: String...) -> String? {
        value(for: keys)?.stringValue
    }

    func int(for keys: String...) -> Int? {
        value(for: keys)?.intValue
    }

    func bool(for keys: String...) -> Bool? {
        value(for: keys)?.boolValue
    }

    func uuid(for keys: String...) -> UUID? {
        value(for: keys)?.uuidValue
    }

    func object(for keys: String...) -> [String: JSONValue]? {
        value(for: keys)?.objectValue
    }

    func array(for keys: String...) -> [JSONValue]? {
        value(for: keys)?.arrayValue
    }
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct InvitationAcceptRequest: Codable {
    let token: String
    let password: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case token
        case password
        case fullName = "full_name"
    }
}

struct RefreshRequest: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct EmployeeProfileUpdateRequest: Codable {
    let profile: [String: JSONValue]
}

struct DiscSubmissionRequest: Codable {
    let employeeID: UUID
    let answers: [String: JSONValue]

    enum CodingKeys: String, CodingKey {
        case employeeID = "employee_id"
        case answers
    }
}

struct MotivationSubmissionRequest: Codable {
    let employeeID: UUID
    let answers: [String: JSONValue]

    enum CodingKeys: String, CodingKey {
        case employeeID = "employee_id"
        case answers
    }
}

struct PulseSubmissionRequest: Codable {
    let mood: Int
    let stress: Int
    let workload: Int
    let recognition: Int
    let relationships: Int
    let intentToLeave: Int

    enum CodingKeys: String, CodingKey {
        case mood
        case stress
        case workload
        case recognition
        case relationships
        case intentToLeave = "intent_to_leave"
    }
}
