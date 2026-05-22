//
//  NodeRowView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

struct NodeRowView: View {

    let node: EditorNode
    let isFocused: Bool
    let onTitleChanged: (String) -> Void
    let onContentChanged: (UUID, String) -> Void
    let onCommand: (NodeCommand) -> Void
    let onFocused: (UUID) -> Void
    private let logger = ConsoleLogger()

    private var debugLog: Void {
        logger.debug("渲染节点「\(node.title)」，children 数量：\(node.children.count)", function: #function)
    }

    var body: some View {
        let _ = debugLog
        
        HStack(alignment: .top, spacing: 0) {
            // 左侧缩进导轨
            NodeIndentationGuide(depth: node.depth)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 类型指示器
                    NodeTypeIndicator(depth: node.depth)
                    
                    // 折叠控件（有子节点时显示）
                    if !node.children.isEmpty {
                        NodeCollapseControl(isCollapsed: node.isCollapsed) {
                            onCommand(.toggleCollapse(nodeID: node.id))
                        }
                    }

                    // 标题输入框
                    NodeTitleEditor(
                        text: node.title,
                        depth: node.depth,
                        isFocused: isFocused,
                        onTextChanged: { onTitleChanged($0) },
                        onReturn: { onCommand(.insertAfter(nodeID: node.id)) },
                        onBackspaceWhenEmpty: { },
                        onTab: { onCommand(.indent(nodeID: node.id)) },
                        onShiftTab: { onCommand(.outdent(nodeID: node.id)) },
                        onMoveUp: { onCommand(.moveUp(nodeID: node.id)) },
                        onMoveDown: { onCommand(.moveDown(nodeID: node.id)) },
                        onDelete: { onCommand(.delete(nodeID: node.id)) },
                        onFocus: { onFocused(node.id) }
                    )
                    Spacer()
                }

                // Block 内容区（MVP 只有 text 类型）
                BlockListView(                    // 原来是内联 ForEach
                    blocks: node.blocks,
                    onContentChanged: onContentChanged,
                    onFocused: { onFocused(node.id) }
                )
                .padding(.leading, node.children.isEmpty ? 16 : 38)
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .background(
            isFocused
            ? ColorTokens.backgroundSecondary
            : ColorTokens.backgroundPrimary
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

#Preview {
    let node = EditorNode(
        id: UUID(),
        title: "示例节点",
        depth: 0,
        sortIndex: 1000,
        children: [
            EditorNode(
                id: UUID(),
                title: "子节点",
                depth: 1,
                sortIndex: 1000
            )
        ],
        blocks: [
            EditorBlock(id: UUID(), type: .text, content: "节点内容文字", sortIndex: 1000)
        ]
    )
    VStack(spacing: 0) {
        NodeRowView(
            node: node,
            isFocused: true,
            onTitleChanged: { _ in },
            onContentChanged: { _, _ in },
            onCommand: { _ in },
            onFocused: { _ in }
        )
        NodeRowView(
            node: EditorNode(id: UUID(), title: "未聚焦节点", depth: 0, sortIndex: 2000),
            isFocused: false,
            onTitleChanged: { _ in },
            onContentChanged: { _, _ in },
            onCommand: { _ in },
            onFocused: { _ in }
        )
    }
    .padding(.horizontal)
}
