//
//  NodeTypeIndicator.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

/// 节点类型指示器。有子节点时兼做折叠/展开按钮：
/// 折叠 → circle.fill，展开 → circle，无子节点 → circle（不可点击）。
struct NodeTypeIndicator: View {

    let hasChildren: Bool
    let isCollapsed: Bool
    let onToggle: (() -> Void)?

    var body: some View {
        if hasChildren, let onToggle {
            Button(action: onToggle) {
                bulletIcon
            }
            .buttonStyle(.plain)
        } else {
            bulletIcon
        }
    }

    private var bulletIcon: some View {
        Image(systemName: hasChildren && isCollapsed ? "circle.fill" : "circle")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(ColorTokens.textSecondary)
            .frame(width: 16, height: 16)
            .contentShape(Rectangle())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
            NodeTypeIndicator(hasChildren: false, isCollapsed: false, onToggle: nil)
            Text("无子节点").font(.caption)
        }
        HStack(spacing: 8) {
            NodeTypeIndicator(hasChildren: true, isCollapsed: false, onToggle: {})
            Text("有子节点·展开").font(.caption)
        }
        HStack(spacing: 8) {
            NodeTypeIndicator(hasChildren: true, isCollapsed: true, onToggle: {})
            Text("有子节点·折叠").font(.caption)
        }
    }
    .padding()
}
