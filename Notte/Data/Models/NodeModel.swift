//
//  NodeModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

@Model
nonisolated class NodeModel {
    @Attribute(.unique) var id: UUID = UUID()
    var pageID: UUID = UUID()
    var parentNodeID: UUID? = nil
    var title: String = ""
    var sortIndex: Double = 0
    var isCollapsed: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        pageID: UUID,
        parentNodeID: UUID? = nil,
        title: String,
        sortIndex: Double = 0,
        isCollapsed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.pageID = pageID
        self.parentNodeID = parentNodeID
        self.title = title
        self.sortIndex = sortIndex
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension NodeModel {
    func toDomain() -> Node {
        Node(
            id: id,
            pageID: pageID,
            parentNodeID: parentNodeID,
            title: title,
            sortIndex: sortIndex,
            isCollapsed: isCollapsed,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension NodeModel: SortIndexPersistable {}
