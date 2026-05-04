//
//  NodeIndentationGuide.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

/// 根据 depth 渲染左侧缩进占位和层级竖线。
struct NodeIndentationGuide: View {

    let depth: Int

    private let indentWidth: CGFloat = 20
    private let lineWidth: CGFloat = 1

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<depth, id: \.self) { _ in
                ZStack(alignment: .leading) {
                    ColorTokens.backgroundPrimary
                        .frame(width: indentWidth)
                    Rectangle()
                        .fill(ColorTokens.separator.opacity(0.4))
                        .frame(width: lineWidth)
                        .padding(.leading, indentWidth / 2 - lineWidth / 2)
                }
            }
        }
    }
}
