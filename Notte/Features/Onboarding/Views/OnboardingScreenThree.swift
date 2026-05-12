//
//  OnboardingScreenThree.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/12.
//

import SwiftUI

struct OnboardingScreenThree: View {
    let onCreateFirstCollection: () -> Void
    let onImportSampleData: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Text("准备好了吗？")
                .font(TypographyTokens.largeTitle)
                .foregroundStyle(ColorTokens.textPrimary)
            Text("选择一种方式开始")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(spacing: SpacingTokens.sm) {
                Button(action: onCreateFirstCollection) {
                    Text("创建我的第一个 Collection")
                        .font(TypographyTokens.body.bold())
                        .padding(.horizontal, SpacingTokens.md)
                        .padding(.vertical, SpacingTokens.xs)
                }
                .buttonStyle(.glassProminent)
                .tint(ColorTokens.accent)

                Button(action: onImportSampleData) {
                    Text("导入示例数据")
                        .font(TypographyTokens.body)
                        .padding(.horizontal, SpacingTokens.md)
                        .padding(.vertical, SpacingTokens.xs)
                }
                .buttonStyle(.glass)
            }
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
    }
}

#Preview {
    OnboardingScreenThree(onCreateFirstCollection: {}, onImportSampleData: {})
}
