//
//  OnboardingScreenThree.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/12.
//

import SwiftUI

struct OnboardingScreenThree: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Text("准备好了吗？")
                .font(TypographyTokens.largeTitle)
                .foregroundStyle(ColorTokens.textPrimary)
            Text("选择一种方式开始")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textSecondary)
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
    }
}

#Preview {
    OnboardingScreenThree()
}
