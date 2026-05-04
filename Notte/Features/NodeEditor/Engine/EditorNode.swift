//
//  EditorNode.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/12.
//

import Foundation

/// Node 编辑器的运行时模型。
/// 存储模型（NodeModel/Node）是扁平的，EditorNode 是树形的，
/// 由 NodeQueryService.buildTree 从扁平列表构建。
struct EditorNode: Identifiable, Equatable {
    let id: UUID
    var parentID: UUID?
    var title: String
    var depth: Int
    var sortIndex: Double
    var isCollapsed: Bool
    var isVisible: Bool
    var children: [EditorNode]
    var blocks: [EditorBlock]
    
    init(
        id: UUID,
        parentID: UUID? = nil,
        title: String,
        depth: Int,
        sortIndex: Double,
        isCollapsed: Bool = false,
        isVisible: Bool = true,
        children: [EditorNode] = [],
        blocks: [EditorBlock] = []
    ) {
        self.id = id
        self.parentID = parentID
        self.title = title
        self.depth = depth
        self.sortIndex = sortIndex
        self.isCollapsed = isCollapsed
        self.isVisible = isVisible
        self.children = children
        self.blocks = blocks
    }
}
