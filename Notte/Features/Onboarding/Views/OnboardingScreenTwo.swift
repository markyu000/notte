//
//  OnboardingScreenTwo.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/12.
//

import SwiftUI

struct OnboardingScreenTwo: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Text("三个对象，一套系统")
                .font(TypographyTokens.largeTitle)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(alignment: .leading, spacing: SpacingTokens.md) {
                conceptRow(
                    icon: "tray.full",
                    title: "Collection",
                    subtitle: "专题空间，按主题组织所有内容"
                )
                conceptRow(
                    icon: "doc.text",
                    title: "Page",
                    subtitle: "一篇完整的笔记或文档"
                )
                conceptRow(
                    icon: "list.bullet.indent",
                    title: "Node",
                    subtitle: "可自由移动、重组的内容模块"
                )
            }
            .padding(SpacingTokens.lg)
            .background(ColorTokens.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
    }

    private func conceptRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: SpacingTokens.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ColorTokens.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                Text(title)
                    .font(TypographyTokens.title)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(subtitle)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }
}

#Preview {
    OnboardingScreenTwo()
}
