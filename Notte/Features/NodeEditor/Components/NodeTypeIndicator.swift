//
//  NodeTypeIndicator.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

/// 每行左侧的类型指示圆点，根据 depth 调整大小与填充样式。
/// depth 0 为实心圆（主标题级），其余为空心圆（子级节点）。
struct NodeTypeIndicator: View {

    let depth: Int

    private var size: CGFloat {
        depth == 0 ? 8 : 6
    }

    private var isFilled: Bool {
        depth == 0
    }

    var body: some View {
        Circle()
            .fill(isFilled ? ColorTokens.accent : Color.clear)
            .overlay(
                Circle()
                    .stroke(ColorTokens.accent.opacity(0.6), lineWidth: 1.5)
            )
            .frame(width: size, height: size)
    }
}
