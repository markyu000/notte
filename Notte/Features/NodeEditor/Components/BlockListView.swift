//
//  BlockListView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/26.
//

import SwiftUI
import SwiftData

/// Node 内容区：顺序渲染该 Node 的所有 Block。
/// MVP 阶段只有 .text 类型，POST 阶段扩展类型时在 switch 里添加对应 BlockView 即可。
struct BlockListView: View {

    let blocks: [EditorBlock]
    @Binding var requestFocus: Bool
    let onContentChanged: (UUID, String) -> Void
    let onFocusGained: () -> Void
    let onFocusLost: () -> Void
    var onTab: () -> Void = {}
    var onShiftTab: () -> Void = {}
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        ForEach(blocks) { block in
            switch block.type {
            case .text:
                NodeContentEditor(
                    text: block.content,
                    font: TypographyTokens.body,
                    placeholder: "内容",
                    requestFocus: $requestFocus,
                    onTextChanged: { onContentChanged(block.id, $0) },
                    onBackspaceWhenEmpty: { },
                    onFocusGained: onFocusGained,
                    onFocusLost: onFocusLost,
                    onTab: onTab,
                    onShiftTab: onShiftTab,
                    onMoveUp: onMoveUp,
                    onMoveDown: onMoveDown,
                    onDelete: onDelete
                )
                .padding(.leading, 4)
            }
        }
    }
}

#Preview {
    @Previewable @State var requestFocus = false
    let blocks = [
        EditorBlock(id: UUID(), type: .text, content: "第一段内容", sortIndex: 1000),
        EditorBlock(id: UUID(), type: .text, content: "第二段内容", sortIndex: 2000)
    ]
    VStack(alignment: .leading) {
        BlockListView(
            blocks: blocks,
            requestFocus: $requestFocus,
            onContentChanged: { _, _ in },
            onFocusGained: {},
            onFocusLost: {}
        )
    }
    .padding()
}
