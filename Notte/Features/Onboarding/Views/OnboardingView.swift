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
                Button {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("跳过")
                        .padding(.vertical, SpacingTokens.xs)
                        .padding(.horizontal, SpacingTokens.xs)
                }
                .font(TypographyTokens.body)
                .buttonStyle(.glass)
                .padding(.vertical, SpacingTokens.sm)
                .padding(.horizontal, SpacingTokens.md)
            }
            .padding(.trailing, SpacingTokens.sm)

            TabView(selection: $viewModel.currentPage) {
                OnboardingScreenOne()
                    .padding(.bottom, SpacingTokens.xl * 3)
                    .tag(0)
                OnboardingScreenTwo()
                    .padding(.bottom, SpacingTokens.xl * 3)
                    .tag(1)
                OnboardingScreenThree()
                    .padding(.bottom, SpacingTokens.xl * 3)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            ctaArea
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.currentPage < 2)
                .padding(.horizontal, SpacingTokens.md)
                .padding(.bottom, SpacingTokens.lg)
        }
        .background(ColorTokens.backgroundPrimary)
    }

    @ViewBuilder
    private var ctaArea: some View {
        if viewModel.currentPage < 2 {
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                    viewModel.next()
                }
            }) {
                Text("下一步")
                    .font(TypographyTokens.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SpacingTokens.sm)
            }
            .buttonStyle(.glassProminent)
            .tint(ColorTokens.accent)
            .padding(.top, SpacingTokens.sm)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            VStack(spacing: SpacingTokens.sm) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        hasCompletedOnboarding = true
                    }
                    onCreateFirstCollection()
                }) {
                    Text("创建我的第一个 Collection")
                        .font(TypographyTokens.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SpacingTokens.sm)
                }
                .buttonStyle(.glassProminent)
                .tint(ColorTokens.accent)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        hasCompletedOnboarding = true
                    }
                    onImportSampleData()
                }) {
                    Text("导入示例数据")
                        .font(TypographyTokens.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SpacingTokens.sm)
                }
                .buttonStyle(.glass)
            }
            .padding(.top, SpacingTokens.sm)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

#Preview {
    OnboardingView(
        onCreateFirstCollection: {},
        onImportSampleData: {}
    )
}
