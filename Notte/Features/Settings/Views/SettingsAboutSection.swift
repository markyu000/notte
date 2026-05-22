//
//  SettingsAboutSection.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import SwiftUI

struct SettingsAboutSection: View {
    let version: String

    private let feedbackURL = URL(string: "mailto:feedback@notte.app")!
    private let privacyURL = URL(string: "https://notte.app/privacy")!

    var body: some View {
        Section("关于 Notte") {
            HStack {
                Text("版本")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Text(version)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Link(destination: feedbackURL) {
                Label("反馈与建议", systemImage: "envelope")
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            Link(destination: privacyURL) {
                Label("隐私政策", systemImage: "hand.raised")
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
    }
}
