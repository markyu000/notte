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

    init() {}
}
