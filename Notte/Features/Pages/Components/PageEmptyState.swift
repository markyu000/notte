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

            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(spacing: SpacingTokens.sm) {
                Text("还没有页面")
                    .font(TypographyTokens.title)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("点击下方按钮创建第一个页面")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateTapped) {
                Label("新建页面", systemImage: "plus")
                    .font(TypographyTokens.body)
                    .padding(.horizontal, SpacingTokens.lg)
                    .padding(.vertical, SpacingTokens.sm)
                    .background(ColorTokens.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(SpacingTokens.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PageEmptyState(onCreateTapped: {})
}