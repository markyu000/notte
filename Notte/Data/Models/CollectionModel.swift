//
//  CollectionModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

@Model
class CollectionModel {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var iconName: String? = nil
    var colorToken: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortIndex: Double = 0
    var isPinned: Bool = false

    init(
        id: UUID,
        title: String,
        iconName: String? = nil,
        colorToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortIndex: Double = 0,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.colorToken = colorToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortIndex = sortIndex
        self.isPinned = isPinned
    }
}

extension CollectionModel {
    func toDomain() -> Collection {
        Collection(
            id: id,
            title: title,
            iconName: iconName,
            colorToken: colorToken,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortIndex: sortIndex,
            isPinned: isPinned
        )
    }
}
