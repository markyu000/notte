//
//  CloudKitSyncLogger.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/17.
//

import Foundation
import CoreData
import Combine

/// 监听 SwiftData + CloudKit 底层的同步事件，向 UI 层暴露同步状态。
/// SwiftData 的 CloudKit 集成底层仍通过 NSPersistentCloudKitContainer 发出通知。
@MainActor
final class CloudKitSyncLogger: ObservableObject {

    struct SyncEvent: Identifiable {
        let id = UUID()
        let date: Date
        let eventType: String
        let succeeded: Bool
        let errorDescription: String?
    }

    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncFailed: Bool = false
    @Published private(set) var syncError: Error?
    @Published private(set) var eventLog: [SyncEvent] = []

    private var observer: NSObjectProtocol?
    private let maxLogSize = 50

    init() {
        restoreLastSyncDate()
    }

    deinit {
        // deinit 不受 @MainActor 约束，可能在任意线程被调用；
        // NotificationCenter.removeObserver 是线程安全的，可直接调用。
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let event = notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event
            else { return }
            Task { @MainActor [weak self] in
                self?.handle(event: event)
            }
        }
    }

    private func restoreLastSyncDate() {
        let ts = UserDefaults.standard.double(forKey: "lastSyncDate")
        lastSyncDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    private func handle(event: NSPersistentCloudKitContainer.Event) {
        let typeName: String
        switch event.type {
        case .setup:   typeName = "setup"
        case .import:  typeName = "import"
        case .export:  typeName = "export"
        @unknown default: typeName = "unknown"
        }

        let logEntry = SyncEvent(
            date: event.endDate ?? Date(),
            eventType: typeName,
            succeeded: event.succeeded,
            errorDescription: event.error?.localizedDescription
        )
        eventLog.insert(logEntry, at: 0)
        if eventLog.count > maxLogSize { eventLog.removeLast() }

        if let error = event.error {
            syncFailed = true
            syncError = error
        } else if event.succeeded && event.type != .setup {
            // .setup 事件表示 CloudKit schema 初始化完成，不代表用户数据已同步，
            // 不应记录为"上次同步时间"。
            syncFailed = false
            syncError = nil
            let now = event.endDate ?? Date()
            lastSyncDate = now
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "lastSyncDate")
        }
    }
}
