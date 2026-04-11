//
//  BlockRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class BlockRepository: BlockRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in nodeID: UUID) async throws -> [Block] {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.nodeID == nodeID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func fetch(by id: UUID) async throws -> Block? {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first.map { $0.toDomain() }
    }

    func create(_ block: Block) async throws {
        let model = BlockModel(
            id: block.id,
            nodeID: block.nodeID,
            type: block.type.rawValue,
            content: block.content,
            sortIndex: block.sortIndex,
            createdAt: block.createdAt,
            updatedAt: block.updatedAt
        )
        context.insert(model)
        try context.save()
    }

    func update(_ block: Block) async throws {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.id == block.id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.nodeID = block.nodeID
        model.type = block.type.rawValue
        model.content = block.content
        model.sortIndex = block.sortIndex
        model.updatedAt = block.updatedAt
        try context.save()
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }

    func deleteAll(in nodeID: UUID) async throws {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.nodeID == nodeID }
        )
        let models = try context.fetch(descriptor)
        for model in models {
            context.delete(model)
        }
        try context.save()
    }
}
