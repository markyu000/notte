//
//  NodeHierarchyPolicy.swift
//  Notte
//
//  Created by 余哲源 on 2026/6/6.
//

import Foundation

/// Node 层级规则的单一真相源。
/// UI 层(ViewModel/View)与数据层(NodeMutationService)都从这里取规则,
/// 避免规则散落、各写一份。

enum NodeHierarchyPolicy {
    /// 允许的最大标题层级数(第一级到第五级)
    static let maxLevel = 5
    /// 允许的最大 depth(depth 从 0 起算,故为 maxLevel - 1 = 4)
    static let maxDepth = maxLevel - 1

    /// 给定父节点的 depth,判断其下是否还能再加一层子节点。
    /// - Parameter parentDepth: 将成为父节点的那个节点的 depth
    /// - Returns: 子节点 depth = parentDepth + 1,不超过 maxDepth 时为 true
    static func canAddChild(parentDepth: Int) -> Bool {
        parentDepth < maxDepth
    }

    /// 给定子树(含自身)的最大 depth,判断整棵子树能否再缩进一级。
    /// 缩进会让整个子树 depth +1,故最深节点 +1 后不得超过 maxDepth。
    static func canIndent(subtreeMaxDepth: Int) -> Bool {
        subtreeMaxDepth < maxDepth
    }
}
