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
                OnboardingScreenThree()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            ctaArea
                .padding(.horizontal, SpacingTokens.md)
                .padding(.bottom, SpacingTokens.lg)
        }
        .background(ColorTokens.backgroundPrimary)
    }

    @ViewBuilder
    private var ctaArea: some View {
        if viewModel.currentPage < 2 {
            Button(action: viewModel.next) {
                Text("下一步")
                    .font(TypographyTokens.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SpacingTokens.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(ColorTokens.accent)
            .padding(.top, SpacingTokens.sm)
        } else {
            VStack(spacing: SpacingTokens.sm) {
                Button(action: {
                    hasCompletedOnboarding = true
                    onCreateFirstCollection()
                }) {
                    Text("创建我的第一个 Collection")
                        .font(TypographyTokens.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SpacingTokens.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(ColorTokens.accent)

                Button(action: {
                    hasCompletedOnboarding = true
                    onImportSampleData()
                }) {
                    Text("导入示例数据")
                        .font(TypographyTokens.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SpacingTokens.sm)
                }
                .buttonStyle(.bordered)
                .tint(ColorTokens.accent)
            }
            .padding(.top, SpacingTokens.sm)
        }
    }
}

#Preview {
    OnboardingView(
        onCreateFirstCollection: {},
        onImportSampleData: {}
    )
}
