//
//  BlockListView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/26.
//

import SwiftUI

/// Node 内容区：顺序渲染该 Node 的所有 Block。
/// MVP 阶段只有 .text 类型，POST 阶段扩展类型时在 switch 里添加对应 BlockView 即可。
struct BlockListView: View {

    let blocks: [EditorBlock]
    let onContentChanged: (UUID, String) -> Void
    let onFocused: () -> Void

    var body: some View {
        ForEach(blocks) { block in
            switch block.type {
            case .text:
                NodeContentEditor(
                    text: block.content,
                    font: TypographyTokens.body,
                    placeholder: "内容",
                    onTextChanged: { onContentChanged(block.id, $0) },
                    onReturn: { },
                    onBackspaceWhenEmpty: { },
                    onTab: { },
                    onShiftTab: { },
                    onFocus: onFocused
                )
                .padding(.leading, 4)
            }
        }
    }
}
