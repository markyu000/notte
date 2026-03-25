//
//  Page.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/25.
//

import Foundation

struct Page: Identifiable, Hashable {
    let id: UUID
    let collectionID: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isArchived: Bool
}
