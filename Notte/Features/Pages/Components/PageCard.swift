//
//  PageRow.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import SwiftUI

struct PageCard: View {
    let page: Page

    var body: some View {
        HStack(spacing: SpacingTokens.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 18))
                .foregroundStyle(ColorTokens.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                Text(page.title)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)

                Text(page.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, SpacingTokens.sm)
        .padding(.horizontal, SpacingTokens.md)
    }
}

#Preview {
    PageCard(page: Page(
        id: UUID(),
        collectionID: UUID(),
        title: "SwiftUI 学习笔记",
        createdAt: Date(),
        updatedAt: Date(),
        sortIndex: 1000,
        isArchived: false
    ))
    .padding()
}
