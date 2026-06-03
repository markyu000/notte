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
    /// 仅当 pendingFocusNodeID == node.id 时为 true，触发标题编辑器 becomeFirstResponder。
    /// 与 isFocused（节点高亮）分离，避免 Block 内容区获焦时标题抢焦点。
    let shouldFocusTitle: Bool
    let onTitleChanged: (String) -> Void
    let onContentChanged: (UUID, String) -> Void
    let onCommand: (NodeCommand) -> Void
    let onFocused: (UUID) -> Void

    /// 控制 Block 内容区是否展开（无内容且未聚焦时为 false，完全不占空间）
    @State private var showBlockArea = false
    /// 一次性聚焦请求：标题回车时写 true，NodeContentEditor 消费后重置
    @State private var requestBlockFocus = false

    private let logger = ConsoleLogger()

    /// 每一级深度的左侧缩进量。层级仅靠缩进 + 标题字号落差表达，不再画竖线。
    private let indentPerLevel: CGFloat = 16

    private var debugLog: Void {
        logger.debug("渲染节点「\(node.title)」，children 数量：\(node.children.count)", function: #function)
    }

    private var hasBlockContent: Bool {
        node.blocks.contains { !$0.content.isEmpty }
    }

    var body: some View {
        let _ = debugLog

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                // 类型指示器（有子节点时兼做折叠/展开按钮）
                NodeTypeIndicator(
                    hasChildren: !node.children.isEmpty,
                    isCollapsed: node.isCollapsed,
                    onToggle: node.children.isEmpty ? nil : {
                        onCommand(.toggleCollapse(nodeID: node.id))
                    }
                )

                // 标题输入框：回车跳转到 Block 内容区而非新建节点
                NodeTitleEditor(
                    text: node.title,
                    depth: node.depth,
                    isFocused: shouldFocusTitle,
                    onTextChanged: { onTitleChanged($0) },
                    onReturn: {
                        // 先用动画展开内容区，再设聚焦请求（两步分开避免动画上下文干扰 becomeFirstResponder）
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            showBlockArea = true
                        }
                        requestBlockFocus = true
                    },
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

            // Block 内容区：无内容且 showBlockArea = false 时完全隐藏不占空间；
            // showBlockArea 或 hasBlockContent 为 true 时显示。
            // 展开由 withAnimation 驱动（标题回车），收起由 onFocusLost 内的 withAnimation 驱动。
            if showBlockArea || hasBlockContent {
                BlockListView(
                    blocks: node.blocks,
                    requestFocus: $requestBlockFocus,
                    onContentChanged: onContentChanged,
                    onFocusGained: {
                        showBlockArea = true
                        onFocused(node.id)
                    },
                    onFocusLost: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            showBlockArea = false
                            // hasBlockContent 由 computed property 实时求值；
                            // 若有内容，if 条件仍为 true，视图不会消失
                        }
                    },
                    onTab: { onCommand(.indent(nodeID: node.id)) },
                    onShiftTab: { onCommand(.outdent(nodeID: node.id)) },
                    onMoveUp: { onCommand(.moveUp(nodeID: node.id)) },
                    onMoveDown: { onCommand(.moveDown(nodeID: node.id)) },
                    onDelete: { onCommand(.delete(nodeID: node.id)) }
                )
                .padding(.leading, 22)
                .transition(.opacity)
            }
        }
        .padding(.leading, CGFloat(node.depth) * indentPerLevel)
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
            shouldFocusTitle: false,
            onTitleChanged: { _ in },
            onContentChanged: { _, _ in },
            onCommand: { _ in },
            onFocused: { _ in }
        )
        NodeRowView(
            node: EditorNode(id: UUID(), title: "未聚焦节点", depth: 0, sortIndex: 2000),
            isFocused: false,
            shouldFocusTitle: false,
            onTitleChanged: { _ in },
            onContentChanged: { _, _ in },
            onCommand: { _ in },
            onFocused: { _ in }
        )
    }
    .padding(.horizontal)
}
