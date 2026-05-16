//
//  OnboardingHierarchyIllustration.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/12.
//

import SwiftUI

/// 静态层级示意图：Collection → Page → Node → Block。
/// 用 SwiftUI 原生组件绘制，不依赖外部素材，深浅色自动适配。
struct OnboardingHierarchyIllustration: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            tier(icon: "tray.full", title: "Collection", indent: 0)
            tier(icon: "doc.text", title: "Page", indent: 1)
            tier(icon: "list.bullet.indent", title: "Node", indent: 2)
            tier(icon: "text.alignleft", title: "Block", indent: 3)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tier(icon: String, title: String, indent: Int) -> some View {
        HStack(spacing: SpacingTokens.sm) {
            ForEach(0..<indent, id: \.self) { _ in
                Rectangle()
                    .fill(ColorTokens.separator.opacity(0.4))
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, SpacingTokens.xs)
            }
            Image(systemName: icon)
                .foregroundStyle(ColorTokens.accent)
            Text(title)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textPrimary)
        }
    }
}

#Preview {
    OnboardingHierarchyIllustration()
}
