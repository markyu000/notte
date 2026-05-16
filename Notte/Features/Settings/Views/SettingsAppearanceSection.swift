//
//  SettingsAppearanceSection.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import SwiftUI

struct SettingsAppearanceSection: View {
    var body: some View {
        Section("外观") {
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(ColorTokens.textSecondary)
                Text("跟随系统")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            Text("Notte 会自动适配你在系统设置中选择的浅色或深色模式。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }
}
