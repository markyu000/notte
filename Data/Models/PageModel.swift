//
//  PageModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

@Model
class PageModel {
    @Attribute(.unique) var id: UUID = UUID()
    var collectionID: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortIndex: Double = 0
    var isArchived: Bool = false

    init(
        id: UUID = UUID(),
        collectionID: UUID,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortIndex: Double = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.collectionID = collectionID
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortIndex = sortIndex
        self.isArchived = isArchived
    }
}
