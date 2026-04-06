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

            Image(systemName: "tray")
                .font(.system(size: 70))
                .foregroundStyle(ColorTokens.accent)

            VStack(spacing: SpacingTokens.sm) {
                Text("还没有Collection")
                    .font(TypographyTokens.title)
                    .bold()
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("点击下方按钮创建第一个Collection")
                    .font(TypographyTokens.boldBody)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateTapped) {
                Label("新建Collection", systemImage: "plus")
                    .font(TypographyTokens.boldBody)
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
        .background(ColorTokens.backgroundPrimary)
    }
}

#Preview {
    CollectionEmptyState(onCreateTapped: {})
}
