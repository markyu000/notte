//
//  NodeCollapseControl.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

/// 折叠/展开控制按钮，仅在节点有子节点时由 NodeRowView 渲染。
struct NodeCollapseControl: View {

    let isCollapsed: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        } label: {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
                .rotationEffect(.degrees(isCollapsed ? 0 : 90))
        }
        .buttonStyle(.plain)
    }
}
