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
    static let effectiveICloudSyncEnabled: Bool = {
        #if DEBUG
        return false
        #else
        return UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true
        #endif
    }()

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
        effectiveICloudSyncEnabled ? .automatic : .none
    }
}
