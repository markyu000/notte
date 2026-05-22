//
//  NodeTypeIndicator.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

/// 节点类型指示器。MVP 阶段只渲染 text 类型；类型切换属于 POST。
struct NodeTypeIndicator: View {

    let depth: Int

    var body: some View {
        Image(systemName: bullet(for: depth))
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(ColorTokens.textSecondary)
            .frame(width: 12, height: 12)
    }

    private func bullet(for depth: Int) -> String {
        depth == 0 ? "circle.fill" : "circle"
    }
}
