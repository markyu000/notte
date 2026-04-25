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
                BlockListView(                    // 原来是内联 ForEach
                    blocks: node.blocks,
                    onContentChanged: onContentChanged
                )
            }
        }
        .padding(.vertical, 6)
    }
}
