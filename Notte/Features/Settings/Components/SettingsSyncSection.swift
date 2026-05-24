//
//  SettingsSyncSection.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import SwiftUI

struct SettingsSyncSection: View {
    @EnvironmentObject private var syncLogger: CloudKitSyncLogger
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true

    private var syncToggleBinding: Binding<Bool> {
        Binding(
            get: { iCloudSyncEnabled },
            set: { newValue in withAnimation(.easeInOut(duration: 0.25)) { iCloudSyncEnabled = newValue } }
        )
    }

    var body: some View {
        Section {
            Toggle("同步到 iCloud", isOn: syncToggleBinding)

            HStack(spacing: SpacingTokens.sm) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(TypographyTokens.body)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .contentTransition(.opacity)
                    Text(statusSubtitle)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .contentTransition(.opacity)
                }
                Spacer()
            }
            .padding(.vertical, 2)
        } header: {
            Text("iCloud 同步")
        } footer: {
            if iCloudSyncEnabled != PersistenceController.effectiveICloudSyncEnabled {
                Text("更改将在重启后生效。")
                    .foregroundStyle(.orange)
            } else if iCloudSyncEnabled {
                Text("你的 Collection、Page、Node 将自动同步到所有 Apple 设备。")
            } else {
                Text("iCloud 同步已关闭，数据仅保存在本设备。")
            }
        }
    }

    private var iconName: String {
        guard iCloudSyncEnabled else { return "icloud.slash" }
        return syncLogger.syncFailed ? "icloud.slash" : "icloud"
    }

    private var iconColor: Color {
        guard iCloudSyncEnabled, !syncLogger.syncFailed else { return ColorTokens.textSecondary }
        return .blue
    }

    private var statusTitle: String {
        guard iCloudSyncEnabled else { return "已关闭" }
        return syncLogger.syncFailed ? "同步失败" : "已开启"
    }

    private var statusSubtitle: String {
        guard iCloudSyncEnabled else { return "数据仅保存在本设备" }
        guard let date = syncLogger.lastSyncDate else { return "尚未同步" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return "上次同步：\(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

#Preview {
    List {
        SettingsSyncSection()
    }
    .listStyle(.insetGrouped)
    .environmentObject(CloudKitSyncLogger())
}
