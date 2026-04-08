//
//  CollectionEmptyState.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/1.
//

import SwiftUI

struct CollectionEmptyState: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 70))
                .foregroundStyle(ColorTokens.accent)

            VStack(spacing: SpacingTokens.sm) {
                Text("用 Collection 整理你的内容")
                    .font(TypographyTokens.title)
                    .bold()
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("把相关的 Page 放在一起")
                    .font(TypographyTokens.subTitle)
                    .bold()
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                Button(action: onCreateTapped) {
                    Label("新建 Collection", systemImage: "square.grid.3x1.folder.badge.plus")
                        .font(TypographyTokens.title2)
                        .padding(.horizontal, SpacingTokens.md)
                        .padding(.vertical, SpacingTokens.xs)
                }
                .buttonStyle(.glass)
            }

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
    CollectionEmptyState(onCreateTapped: {})
}
