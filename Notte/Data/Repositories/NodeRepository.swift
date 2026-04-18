//
//  NodeRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class NodeRepository: NodeRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in pageID: UUID) async throws -> [Node] {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.pageID == pageID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func fetch(by id: UUID) async throws -> Node? {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first.map { $0.toDomain() }
    }

    func create(_ node: Node) async throws {
        let model = NodeModel(
            id: node.id,
            pageID: node.pageID,
            parentNodeID: node.parentNodeID,
            title: node.title,
            depth: node.depth,
            sortIndex: node.sortIndex,
            isCollapsed: node.isCollapsed,
            createdAt: node.createdAt,
            updatedAt: node.updatedAt
        )
        context.insert(model)
        try context.save()
    }

    func update(_ node: Node) async throws {
        let nodeID = node.id
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.id == nodeID }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.pageID = node.pageID
        model.parentNodeID = node.parentNodeID
        model.title = node.title
        model.depth = node.depth
        model.sortIndex = node.sortIndex
        model.isCollapsed = node.isCollapsed
        model.updatedAt = node.updatedAt
        try context.save()
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }

    func deleteAll(in pageID: UUID) async throws {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.pageID == pageID }
        )
        let models = try context.fetch(descriptor)
        for model in models {
            context.delete(model)
        }
        try context.save()
    }
}
