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
    let onBlockCommand: (BlockCommand) -> Void
    let onFocused: (UUID) -> Void

    /// Block 内容区的瞬时展开状态（标题回车 / 正文获焦时为 true）。
    /// 注意这只是「是否因交互展开」，最终是否渲染由 showBlockArea 综合判断。
    @State private var isBlockAreaExpanded = false
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

    /// 正文左缘缩进 = 固定折叠槽位宽度。无论节点有无圆点（leaf / 空标题段落同样），
    /// 正文都从槽位之后的同一 x 起笔，保证同层级所有节点左缘严格对齐。
    private var blockLeadingInset: CGFloat {
        NodeTypeIndicator.slotWidth
    }

    /// 标题行是否渲染。空标题且无子节点、未聚焦时隐藏，节点呈现为纯正文段落（隐形容器）。
    private var showTitleRow: Bool {
        !node.title.isEmpty || !node.children.isEmpty || shouldFocusTitle || isFocused
    }

    /// 正文区是否渲染。标题行隐藏时正文必须常显，保证空标题节点仍有可点击的段落表面。
    private var showBlockArea: Bool {
        isBlockAreaExpanded || hasBlockContent || !showTitleRow
    }

    var body: some View {
        let _ = debugLog

        // 标题与其 Block 用极小间距贴合，节点之间用较大上边距分隔，形成文档流
        VStack(alignment: .leading, spacing: 2) {
            if showTitleRow {
                titleRow
            }
            if showBlockArea {
                blockArea
            }
        }
        .padding(.leading, CGFloat(node.depth) * indentPerLevel)
        .padding(.top, 10)
        .padding(.bottom, 2)
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // 聚焦时不换底色（不再有聚焦盒）；但保留静态不透明背景：
        // 折叠/展开时子节点 zIndex 低于父节点，靠父行不透明背景遮挡，才能呈现「从父节点下方滑出」。
        .background(ColorTokens.backgroundPrimary)
    }

    // MARK: - 子视图

    @ViewBuilder
    private var titleRow: some View {
        // 折叠控件占固定槽位（含右侧间距），故 HStack 间距为 0；正文紧贴槽位之后
        HStack(spacing: 0) {
            // 折叠控件：固定槽位；leaf 空槽位仅占位，父节点圆点按需在槽内浮现
            NodeTypeIndicator(
                hasChildren: !node.children.isEmpty,
                isCollapsed: node.isCollapsed,
                isRevealed: isFocused || shouldFocusTitle,
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
                        isBlockAreaExpanded = true
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
    }

    @ViewBuilder
    private var blockArea: some View {
        // 展开由 withAnimation 驱动（标题回车），收起由 onFocusLost 内的 withAnimation 驱动。
        BlockListView(
            blocks: node.blocks,
            requestFocus: $requestBlockFocus,
            onContentChanged: onContentChanged,
            onFocusGained: {
                isBlockAreaExpanded = true
                onFocused(node.id)
            },
            onFocusLost: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    isBlockAreaExpanded = false
                }
            },
            onTab: { onCommand(.indent(nodeID: node.id)) },
            onShiftTab: { onCommand(.outdent(nodeID: node.id)) },
            onMoveUp: { onCommand(.moveUp(nodeID: node.id)) },
            onMoveDown: { onCommand(.moveDown(nodeID: node.id)) },
            onDelete: { onCommand(.delete(nodeID: node.id)) },
            isSelected: isFocused,
            onMoveBlockUp: { onBlockCommand(.moveBlockUp(blockID: $0)) },
            onMoveBlockDown: { onBlockCommand(.moveBlockDown(blockID: $0)) }
        )
        .padding(.leading, blockLeadingInset)
        .transition(.opacity)
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
            onBlockCommand: { _ in },
            onFocused: { _ in }
        )
        NodeRowView(
            node: EditorNode(id: UUID(), title: "未聚焦节点", depth: 0, sortIndex: 2000),
            isFocused: false,
            shouldFocusTitle: false,
            onTitleChanged: { _ in },
            onContentChanged: { _, _ in },
            onCommand: { _ in },
            onBlockCommand: { _ in },
            onFocused: { _ in }
        )
    }
    .padding(.horizontal)
}
