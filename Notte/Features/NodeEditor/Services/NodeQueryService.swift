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
    func buildTree(nodes: [Node], blocks: [Block]) throws -> [EditorNode] {
        // 1. 将 Block 按 nodeID 分组
        var blocksByNodeID: [UUID: [Block]] = [:]
        for block in blocks {
            blocksByNodeID[block.nodeID, default: []].append(block)
        }

        // 2. 将每个 Node 转为 EditorNode（children 先为空，depth 待递归赋值）
        var editorNodes: [UUID: EditorNode] = [:]
        for node in nodes.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            let nodeBlocks = (blocksByNodeID[node.id] ?? [])
                .sorted { $0.sortIndex < $1.sortIndex }
                .map {
                    EditorBlock(
                        id: $0.id,
                        type: $0.type,
                        content: $0.content,
                        sortIndex: $0.sortIndex,
                        imageWidthRatio: $0.imageWidthRatio,
                        imageAlignment: $0.imageAlignment
                    )
                }

            editorNodes[node.id] = EditorNode(
                id: node.id,
                parentID: node.parentNodeID,
                title: node.title,
                depth: 0,
                sortIndex: node.sortIndex,
                isCollapsed: node.isCollapsed,
                children: [],
                blocks: nodeBlocks
            )
        }

        // 3. 建立父子 ID 映射（按 sortIndex 排序）
        var childIDsByParent: [UUID: [UUID]] = [:]
        for node in nodes.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            guard let parentID = node.parentNodeID else { continue }
            childIDsByParent[parentID, default: []].append(node.id)
        }

        // 递归构建 EditorNode 树：depth 沿途下传（parent.depth + 1），单趟 DFS 算完，
        // 不对每个节点单独往上溯到根——避免 struct 值拷贝导致孙节点丢失。
        // id 取自 nodes 本身（根节点集合 / childIDsByParent），editorNodes 也由 nodes 构建，
        // 找不到意味着这层不变式被破坏，不能悄悄跳过——显式抛 RepositoryError.notFound。
        func buildNode(_ id: UUID, depth: Int) throws -> EditorNode {
            guard var node = editorNodes[id] else {
                throw RepositoryError.notFound
            }
            node.depth = depth
            node.children = try (childIDsByParent[id] ?? []).map { try buildNode($0, depth: depth + 1) }
            return node
        }

        // 4. 收集根节点
        return try nodes
            .filter { $0.parentNodeID == nil }
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { try buildNode($0.id, depth: 0) }
    }

    /// 将树形结构展平为按视觉顺序排列的 EditorNode 列表（深度优先，前序遍历）
    /// 已折叠节点的子树不出现在结果中
    func visibleNodes(from roots: [EditorNode]) -> [EditorNode] {
        var result: [EditorNode] = []
        for root in roots {
            flatten(node: root, into: &result)
        }
        return result
    }

    private func flatten(node: EditorNode, into result: inout [EditorNode]) {
        var visible = node
        visible.isVisible = true
        result.append(visible)
        if !node.isCollapsed {
            for child in node.children.sorted(by: {
                $0.sortIndex < $1.sortIndex
            }) {
                flatten(node: child, into: &result)
            }
        }
    }
}

extension NodeQueryService {
    /// 找到目标节点在同级中的前一个兄弟节点（sortIndex 最大且小于自身的同级节点）
    func previousSibling(of nodeID: UUID, in nodes: [Node]) -> Node? {
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            return nil
        }
        return
            nodes
            .filter {
                $0.parentNodeID == node.parentNodeID
                    && $0.sortIndex < node.sortIndex
            }
            .sorted { $0.sortIndex < $1.sortIndex }
            .last
    }
}

extension NodeQueryService {
    /// 找到目标节点的父节点
    func parent(of nodeID: UUID, in nodes: [Node]) -> Node? {
        guard let node = nodes.first(where: { $0.id == nodeID }),
            let parentID = node.parentNodeID
        else {
            return nil
        }
        return nodes.first { $0.id == parentID }
    }
}

extension NodeQueryService {
    /// 找到目标节点的全部子孙节点（不含自身），BFS 广度优先
    func descendants(of nodeID: UUID, in nodes: [Node]) -> [Node] {
        var result: [Node] = []
        var queue: [UUID] = [nodeID]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let directChildren = nodes.filter { $0.parentNodeID == current }
            result.append(contentsOf: directChildren)
            queue.append(contentsOf: directChildren.map(\.id))
        }
        return result
    }

    /// 找到目标节点的所有直接子节点，按 sortIndex 排序
    func children(of nodeID: UUID, in nodes: [Node]) -> [Node] {
        nodes.filter { $0.parentNodeID == nodeID }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    /// 找到目标节点在同级中的后一个兄弟节点
    func nextSibling(of nodeID: UUID, in nodes: [Node]) -> Node? {
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            return nil
        }
        return
            nodes
            .filter {
                $0.parentNodeID == node.parentNodeID
                    && $0.sortIndex > node.sortIndex
            }
            .sorted { $0.sortIndex < $1.sortIndex }
            .first
    }
}

extension NodeQueryService {
    // 单点查询：沿 parentNodeID 链向上走到根，返回跳数。建字典 O(n) + 沿链上溯 O(链深)。
    /// - Returns: 节点深度；如果节点不存在返回 nil
    func depth(of nodeID: UUID, in nodes: [Node]) -> Int? {
        let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

        // 如果节点不存在，返回 nil
        guard byID[nodeID] != nil else { return nil }

        var d = 0
        var cur = byID[nodeID]?.parentNodeID
        while let id = cur {
            d += 1
            cur = byID[id]?.parentNodeID
        }
        return d  // 根节点返回 0，子节点返回实际深度
    }

    // 子树相对高度：从 nodeID 顺着树往下走到最深的叶子，边走边计数层级，取最大值。
    // 与 buildTree 同一套思路（先按 parentNodeID 分组，再递归 DFS 往下），
    // 只走一趟下行遍历，不需要对每个子孙再单独往上走一次。
    // 建分组表 O(n) + 遍历子树 O(子树大小)，比"对每个子孙分别往上数"更省。
    func subtreeHeight(of nodeID: UUID, in nodes: [Node]) -> Int {
        let childrenByParent = Dictionary(grouping: nodes, by: \.parentNodeID)
        func maxDepth(from id: UUID) -> Int {
            (childrenByParent[id] ?? []).map { 1 + maxDepth(from: $0.id) }.max()
                ?? 0
        }
        return maxDepth(from: nodeID)
    }
}
