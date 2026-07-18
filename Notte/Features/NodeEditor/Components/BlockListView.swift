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
    var canIndent: Bool = true
    var canMoveUp: Bool = true
    var canMoveDown: Bool = true
    /// 所属节点是否处于选中态。仅选中且多块时才显示拖动手柄。
    var isSelected: Bool = false
    var onMoveBlockUp: (UUID) -> Void = { _ in }
    var onMoveBlockDown: (UUID) -> Void = { _ in }

    /// 当前被「拎起」的块；拖动态/选中态时其边界浮现，静止阅读时隐形。
    @State private var liftedBlockID: UUID?

    /// 拖动净位移超过该阈值才触发一格移动（朴素一维移动，不做精确帧测量）。
    private let dragThreshold: CGFloat = 24

    /// 单块节点没有可换位的邻居，无需显示拖动手柄，保持普通文本的文档流外观。
    private var showDragAffordance: Bool {
        isSelected && blocks.count > 1
    }

    var body: some View {
        ForEach(blocks) { block in
            blockRow(block)
        }
    }

    @ViewBuilder
    private func blockRow(_ block: EditorBlock) -> some View {
        HStack(alignment: .top, spacing: 6) {
            if showDragAffordance {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ColorTokens.textSecondary)
                    .frame(width: 16, height: 24)
                    .contentShape(Rectangle())
                    .gesture(liftGesture(for: block.id))
            }
            blockContent(block)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ColorTokens.separator, lineWidth: 1)
                .opacity(liftedBlockID == block.id ? 1 : 0)
        )
        .animation(.easeInOut(duration: 0.15), value: liftedBlockID)
    }

    @ViewBuilder
    private func blockContent(_ block: EditorBlock) -> some View {
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
                onDelete: onDelete,
                canIndent: canIndent,
                canMoveUp: canMoveUp,
                canMoveDown: canMoveDown
            )
        }
    }

    /// 长按拎起 → 上下拖动 → 松手落下。仅一维（顺序），无二维坐标。
    private func liftGesture(for blockID: UUID) -> some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                if case .second = value {
                    liftedBlockID = blockID
                }
            }
            .onEnded { value in
                liftedBlockID = nil
                if case .second(_, let drag?) = value {
                    if drag.translation.height < -dragThreshold {
                        onMoveBlockUp(blockID)
                    } else if drag.translation.height > dragThreshold {
                        onMoveBlockDown(blockID)
                    }
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
            onFocusLost: {},
            isSelected: true
        )
    }
    .padding()
}
