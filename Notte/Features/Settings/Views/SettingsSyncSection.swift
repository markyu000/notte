//
//  SettingsSyncSection.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import SwiftUI

struct SettingsSyncSection: View {
    @EnvironmentObject private var syncLogger: CloudKitSyncLogger

    var body: some View {
        Section("iCloud 同步") {
            HStack(spacing: SpacingTokens.sm) {
                Image(systemName: syncLogger.syncFailed ? "icloud.slash" : "icloud")
                    .foregroundStyle(syncLogger.syncFailed ? ColorTokens.textSecondary : Color.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(syncLogger.syncFailed ? "同步失败" : "已开启")
                        .font(TypographyTokens.body)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(formattedLastSync)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer()
            }
            .padding(.vertical, 2)

            Text("你的 Collection、Page、Node 将自动同步到所有 Apple 设备。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }

    private var formattedLastSync: String {
        guard let date = syncLogger.lastSyncDate else { return "尚未同步" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return "上次同步：\(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
