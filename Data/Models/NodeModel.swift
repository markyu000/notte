//
//  NodeModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

@Model
class NodeModel {
    @Attribute(.unique) var id: UUID = UUID()
    var pageID: UUID = UUID()
    var parentNodeID: UUID? = nil
    var title: String = ""
    var depth: Int = 0
    var sortIndex: Double = 0
    var isCollapsed: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        pageID: UUID,
        parentNodeID: UUID? = nil,
        title: String,
        depth: Int = 0,
        sortIndex: Double = 0,
        isCollapsed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.pageID = pageID
        self.parentNodeID = parentNodeID
        self.title = title
        self.depth = depth
        self.sortIndex = sortIndex
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
