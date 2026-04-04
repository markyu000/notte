//
//  CollectionCard.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/1.
//

import SwiftUI

struct CollectionCard: View {
    let collection: Collection

    var body: some View {
        HStack(spacing: SpacingTokens.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: collection.iconName ?? "folder.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                HStack(spacing: SpacingTokens.xs) {
                    Text(collection.title)
                        .font(TypographyTokens.title)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(1)
                    if collection.isPinned {
                        CollectionPinnedIndicator()
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(ColorTokens.textSecondary)

        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.sm)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.xs)
    }

    private var accentColor: Color {
        if let token = collection.colorToken {
            return Color(token)
        }
        return ColorTokens.accent
    }
}

#Preview {
    CollectionCard(
        collection: Collection(
            id: UUID(),
            title: "示例 Collection",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isPinned: true
        )
    )
    .padding()
}
