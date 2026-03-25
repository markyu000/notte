//
//  Collection.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/25.
//

import Foundation

struct Collection: Identifiable, Hashable {
    let id: UUID
    var title: String
    var iconName: String?
    var colorToken: String?
    var createdAt: Date
    var updatedAt: Data
    var sortIndex: Double
    var isPinned: Bool
}
