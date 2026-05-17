//
//  SyncFailureBanner.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/17.
//

import SwiftUI

/// 同步失败时显示在屏幕顶部的横幅提示。
/// 仅在 CloudKitSyncLogger.syncFailed == true 时由 RootView 展示。
struct SyncFailureBanner: View {
    var body: some View {
        Label("iCloud 同步失败，数据已安全保存在本地", systemImage: "icloud.slash")
            .font(TypographyTokens.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, SpacingTokens.md)
            .padding(.vertical, SpacingTokens.sm + 2)
            .background(Color.red.opacity(0.85), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}
