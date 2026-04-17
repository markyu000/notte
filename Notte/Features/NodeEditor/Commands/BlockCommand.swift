//
//  BlockCommand.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/18.
//

import Foundation

/// Block 内容层的操作命令。
/// 所有影响 Block 内容的操作都通过此枚举统一表达，
/// 由 NodeEditorEngine.dispatch 路由到 BlockEditingService。
enum BlockCommand {
    /// 在指定节点下新增一个指定类型的 Block
    case addBlock(nodeID: UUID, type: BlockType)
    /// 删除指定 Block
    case deleteBlock(blockID: UUID)
    /// 更新 Block 的文本内容
    case updateContent(blockID: UUID, content: String)
    /// 调整 Block 的排序位置
    case reorderBlock(blockID: UUID, newSortIndex: Double)
}
