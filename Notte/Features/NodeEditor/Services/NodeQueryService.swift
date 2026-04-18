//
//  NodeQueryService.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/18.
//

import Foundation

/// 负责 Node 树的只读查询：构建树、展平可见列表、查找父子与兄弟关系。
/// 所有方法均为纯函数，输入 Node 数组，输出查询结果，无副作用。
struct NodeQueryService {
    // MARK: - 树构建

    /// 将扁平 Node 列表 + Block 列表构建为树形 EditorNode 列表（只含根节点）
    func buildTree(nodes: [Node], blocks: [Block]) -> [EditorNode] {
        // 1. 将 Block 按 nodeID 分组
        var blocksByNodeID: [UUID: [Block]] = [:]
        for block in blocks {
            blocksByNodeID[block.nodeID, default: []].append(block)
        }

        // 2. 将每个 Node 转为 EditorNode（children 先为空）
        var editorNodes: [UUID: EditorNode] = [:]
        for node in nodes.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            let nodeBlocks = (blocksByNodeID[node.id] ?? [])
                .sorted { $0.sortIndex < $1.sortIndex }
                .map { EditorBlock(id: $0.id, type: $0.type, content: $0.content, sortIndex: $0.sortIndex) }
            editorNodes[node.id] = EditorNode(
                id: node.id,
                parentID: node.parentNodeID,
                title: node.title,
                depth: node.depth,
                sortIndex: node.sortIndex,
                isCollapsed: node.isCollapsed,
                children: [],
                blocks: nodeBlocks
            )
        }

        // 3. 建立父子关系
        var rootNodes: [EditorNode] = []
        for node in nodes.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            guard let child = editorNodes[node.id] else { continue }
            if let parentID = node.parentNodeID {
                editorNodes[parentID]?.children.append(child)
            } else {
                rootNodes.append(child)
            }
        }

        return rootNodes
    }
}
