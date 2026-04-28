//
//  NodeCommand.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/18.
//

import Foundation

/// Node 结构层的操作命令。
/// 所有影响 Node 树结构的操作都通过此枚举统一表达，
/// 由 NodeEditorEngine.dispatch 路由到 NodeMutationService。
enum NodeCommand {
    /// 在指定节点后插入一个新的同级节点
    case insertAfter(nodeID: UUID)
    /// 在指定节点内部插入一个子节点（成为其最后一个子节点）
    case insertChild(nodeID: UUID)
    /// 删除指定节点及其全部子孙节点和关联 Block
    case delete(nodeID: UUID)
    /// 将节点与前一个同级节点互换位置
    case moveUp(nodeID: UUID)
    /// 将节点与后一个同级节点互换位置
    case moveDown(nodeID: UUID)
    /// 缩进：成为前一个同级节点的最后一个子节点
    case indent(nodeID: UUID)
    /// 反缩进：提升到父节点的同级，排在父节点之后
    case outdent(nodeID: UUID)
    /// 切换折叠/展开状态
    case toggleCollapse(nodeID: UUID)
    /// 更新节点标题
    case updateTitle(nodeID: UUID, title: String)
}
