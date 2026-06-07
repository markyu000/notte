//
//  PersistenceController.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/27.
//

import Foundation
import SwiftData

struct PersistenceController {
    /// 本次启动时读取一次，后续保持不变。更改 UserDefaults 后需重启才能生效。
    /// 忠实反映用户的设定值，供设置页 UI 比较；是否真正连接 CloudKit 由 cloudKitDatabase 决定。
    static let effectiveICloudSyncEnabled: Bool =
        UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)

        if inMemory {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(
                for: schema,
                migrationPlan: NotteMigrationPlan.self,
                configurations: config
            )
        }

        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: cloudKitDatabase
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: NotteMigrationPlan.self,
            configurations: config
        )
    }

    private static var cloudKitDatabase: ModelConfiguration.CloudKitDatabase {
        #if DEBUG
        return .none    // DEBUG 构建不连接 CloudKit，避免污染生产容器
        #else
        return effectiveICloudSyncEnabled ? .automatic : .none
        #endif
    }
}
