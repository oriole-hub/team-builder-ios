//
//  OfflineQueueStore.swift
//  TeamBuilder
//
//  Created by aristarh on 18.04.2026.
//

import Foundation

enum SubmissionKind: String, Codable {
    case disc
    case motivation
    case pulse
}

struct QueuedSubmission: Identifiable, Codable {
    let id: UUID
    let kind: SubmissionKind
    let employeeID: UUID
    let discRequest: DiscSubmissionRequest?
    let motivationRequest: MotivationSubmissionRequest?
    let pulseRequest: PulseSubmissionRequest?
    let createdAt: Date
}

final class OfflineQueueStore {
    private let key = "team_builder.offline_queue"
    private let defaults = UserDefaults.standard

    private(set) var items: [QueuedSubmission]

    init() {
        if
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode([QueuedSubmission].self, from: data)
        {
            items = decoded
        } else {
            items = []
        }
    }

    func append(_ item: QueuedSubmission) {
        items.append(item)
        persist()
    }

    func remove(_ item: QueuedSubmission) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
    }
}
