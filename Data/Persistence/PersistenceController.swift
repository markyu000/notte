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
        let schema = Schema([
            CollectionModel.self,
            PageModel.self,
            NodeModel.self,
            BlockModel.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}
