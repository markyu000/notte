//
//  SettingsDebugSection.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/14.
//

import SwiftUI
import SwiftData

#if DEBUG
struct SettingsDebugSection: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @EnvironmentObject private var syncLogger: CloudKitSyncLogger
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isImporting: Bool = false
    @State private var showSyncLog: Bool = false

    var body: some View {
        Section("调试") {
            Button {
                isImporting = true
                Task {
                    try? await dependencyContainer.makeExampleDataFactory().importAll()
                    isImporting = false
                }
            } label: {
                Label(isImporting ? "导入中..." : "填充示例数据", systemImage: "tray.and.arrow.down")
            }
            .disabled(isImporting)

            Button(role: .destructive) {
                clearAllData()
            } label: {
                Label("清空所有数据", systemImage: "trash")
            }

            Button {
                hasCompletedOnboarding = false
            } label: {
                Label("重新查看引导", systemImage: "arrow.counterclockwise")
            }
            
            Button {
                triggerSyncRefresh()
            } label: {
                Label("触发数据刷新", systemImage: "arrow.clockwise.icloud")
            }

            Button {
                showSyncLog = true
            } label: {
                Label("查看同步日志", systemImage: "list.bullet.clipboard")
            }
        }
        .sheet(isPresented: $showSyncLog) {
            SyncLogSheet(logger: syncLogger)
        }
    }

    private func clearAllData() {
        try? modelContext.delete(model: CollectionModel.self)
        try? modelContext.delete(model: PageModel.self)
        try? modelContext.delete(model: NodeModel.self)
        try? modelContext.delete(model: BlockModel.self)
        try? modelContext.save()
    }
    
    private func triggerSyncRefresh() {
        // SwiftData + CloudKit 同步由框架自动调度，
        // 此处通过刷新 context 中的所有对象来尝试触发推拉。
        modelContext.processPendingChanges()
    }
}
#endif
