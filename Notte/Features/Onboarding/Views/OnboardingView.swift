//
//  OnboardingView.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/12.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    let onCreateFirstCollection: () -> Void
    let onImportSampleData: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("跳过") {
                    hasCompletedOnboarding = true
                }
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(SpacingTokens.md)
            }

            TabView(selection: $viewModel.currentPage) {
                OnboardingScreenOne()
                    .tag(0)
                OnboardingScreenTwo()
                    .tag(1)
                OnboardingScreenThree(
                    onCreateFirstCollection: {
                        hasCompletedOnboarding = true
                        onCreateFirstCollection()
                    },
                    onImportSampleData: {
                        hasCompletedOnboarding = true
                        onImportSampleData()
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(ColorTokens.backgroundPrimary)
    }
}

#Preview {
    OnboardingView(
        onCreateFirstCollection: {},
        onImportSampleData: {}
    )
}
