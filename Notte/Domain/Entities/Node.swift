//
//  Node.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/25.
//

import Foundation

struct Node: Identifiable, Hashable {
    let id: UUID
    let pageID: UUID
    var parentNodeID: UUID?
    var title: String
    var depth: Int
    var sortIndex: Double
    var isCollapsed: Bool
    var createdAt: Date
    var updatedAt: Date
}
