//
//  OnboardingScreenOne.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/12.
//

import SwiftUI

struct OnboardingScreenOne: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Text("结构化地记录一切")
                .font(TypographyTokens.largeTitle)
                .foregroundStyle(ColorTokens.textPrimary)
            Text("Notte 帮助你快速记录，自然形成结构，长期积累知识。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingTokens.lg)
            OnboardingHierarchyIllustration()
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
    }
}

#Preview {
    OnboardingScreenOne()
}
