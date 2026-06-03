//
//  NodeTypeIndicator.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI

/// 节点折叠控件，占据一个「固定宽度槽位」。
/// 无论圆点是否显示，槽位宽度恒定，正文始终从槽位之后的同一 x 起笔，
/// 保证同层级所有节点左缘严格对齐、缩进基线稳定。
///
/// 圆点显隐规则：
/// - leaf（无子节点）：永不显示，但槽位仍占位。
/// - 折叠态父节点：恒显（circle.fill），指示「此处有折叠内容」。
/// - 展开态父节点：仅在 isRevealed（聚焦等）时于固定槽位内浮现。
struct NodeTypeIndicator: View {

    let hasChildren: Bool
    let isCollapsed: Bool
    /// 是否让圆点浮现（如节点聚焦 / 待聚焦）。展开态父节点据此显隐。
    var isRevealed: Bool = false
    let onToggle: (() -> Void)?

    /// 固定槽位宽度（圆点 16 + 右侧间距 6）。正文左缘缩进也用此值对齐。
    static let slotWidth: CGFloat = 22

    private var showsBullet: Bool {
        hasChildren && (isCollapsed || isRevealed)
    }

    var body: some View {
        slotContent
            .frame(width: Self.slotWidth, height: 16, alignment: .leading)
            .animation(.easeInOut(duration: 0.15), value: showsBullet)
    }

    @ViewBuilder
    private var slotContent: some View {
        if hasChildren, let onToggle {
            Button(action: onToggle) {
                bulletIcon
            }
            .buttonStyle(.plain)
            .opacity(showsBullet ? 1 : 0)
            .allowsHitTesting(showsBullet)
        } else if hasChildren {
            bulletIcon.opacity(showsBullet ? 1 : 0)
        }
        // leaf：空槽位，圆点永不渲染，仅保证对齐
    }

    private var bulletIcon: some View {
        Image(systemName: isCollapsed ? "circle.fill" : "circle")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(ColorTokens.accent)
            .frame(width: 16, height: 16)
            .contentShape(Rectangle())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 0) {
            NodeTypeIndicator(hasChildren: false, isCollapsed: false, onToggle: nil)
            Text("leaf·空槽位对齐").font(.caption)
        }
        HStack(spacing: 0) {
            NodeTypeIndicator(hasChildren: true, isCollapsed: false, isRevealed: false, onToggle: {})
            Text("展开·未聚焦（圆点隐，槽位在）").font(.caption)
        }
        HStack(spacing: 0) {
            NodeTypeIndicator(hasChildren: true, isCollapsed: false, isRevealed: true, onToggle: {})
            Text("展开·聚焦浮现").font(.caption)
        }
        HStack(spacing: 0) {
            NodeTypeIndicator(hasChildren: true, isCollapsed: true, onToggle: {})
            Text("折叠·恒显").font(.caption)
        }
    }
    .padding()
}
