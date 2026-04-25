//
//  NodeRowView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

struct NodeRowView: View {

    let node: EditorNode
    let onTitleChanged: (String) -> Void
    let onContentChanged: (UUID, String) -> Void
    let onCommand: (NodeCommand) -> Void

    var body: some View {
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
                    NodeContentEditor(
                        text: node.title,
                        font: TypographyTokens.nodeTitle(depth: node.depth),
                        placeholder: node.depth == 0 ? "标题" : "节点",
                        onTextChanged: { onTitleChanged($0) },
                        onReturn: { onCommand(.insertAfter(nodeID: node.id)) },
                        onBackspaceWhenEmpty: {
                            if node.depth > 0 {
                                onCommand(.outdent(nodeID: node.id))
                            } else {
                                onCommand(.delete(nodeID: node.id))
                            }
                        },
                        onTab: { onCommand(.indent(nodeID: node.id)) },
                        onShiftTab: { onCommand(.outdent(nodeID: node.id)) }
                    )
                    Spacer()
                    AddNodeButton {
                        onCommand(.insertAfter(nodeID: node.id))
                    }
                }

                // Block 内容区（MVP 只有 text 类型）
                ForEach(node.blocks) { block in
                    NodeContentEditor(
                        text: block.content,
                        font: TypographyTokens.body,
                        placeholder: "内容",
                        onTextChanged: { onContentChanged(block.id, $0) },
                        onReturn: { onCommand(.insertAfter(nodeID: node.id)) },
                        onBackspaceWhenEmpty: { },
                        onTab: { },
                        onShiftTab: { }
                    )
                    .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
