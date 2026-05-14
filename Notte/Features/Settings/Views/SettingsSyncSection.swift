//
//  SettingsSyncSection.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import SwiftUI

struct SettingsSyncSection: View {
    var body: some View {
        Section("iCloud 同步") {
            HStack {
                Image(systemName: "icloud")
                    .foregroundStyle(ColorTokens.textSecondary)
                Text("未开启")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Text("即将推出")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Text("启用后，你的 Collection、Page、Node 将自动同步到你的所有 Apple 设备。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }
}
