//
//  PageEmptyState.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import SwiftUI

struct PageEmptyState: View {
    let onCreateTapped: () -> Void
    
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Spacer()

            Image(systemName: "doc.badge.plus")
                .font(.system(size: 70))
                .foregroundStyle(ColorTokens.accent)

            VStack(spacing: SpacingTokens.sm) {
                Text("还没有页面")
                    .font(TypographyTokens.title)
                    .bold()
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("点击下方按钮创建第一个页面")
                    .font(TypographyTokens.subTitle)
                    .bold()
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateTapped) {
                Label("新建页面", systemImage: "document.badge.plus")
                    .font(TypographyTokens.title2)
                    .padding(.horizontal, SpacingTokens.md)
                    .padding(.vertical, SpacingTokens.xs)
            }
            .buttonStyle(.glass)

            Spacer()
            Spacer()
            Spacer()
        }
        .padding(SpacingTokens.xl)
        .frame(maxWidth: .infinity)
        .background(ColorTokens.backgroundPrimary)
    }
}

#Preview {
    PageEmptyState(onCreateTapped: {})
}
