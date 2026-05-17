//
//  PersistenceController.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/27.
//

import Foundation
import SwiftData

struct PersistenceController {
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
//        return .private("iCloud.com.markyu000.notte.debug")
        return .none
        #else
        return .automatic
        #endif
    }
}
