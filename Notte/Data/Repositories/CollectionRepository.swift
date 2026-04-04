//
//  CollectionRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class CollectionRepository: CollectionRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [Collection] {
        let descriptor = FetchDescriptor<CollectionModel>(
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        do {
            let models = try context.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func fetch(by id: UUID) async throws -> Collection? {
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.id == id }
        )
        do {
            return try context.fetch(descriptor).first?.toDomain()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func create(_ collection: Collection) async throws {
        let model = CollectionModel(
            id: collection.id,
            title: collection.title,
            iconName: collection.iconName,
            colorToken: collection.colorToken,
            createdAt: collection.createdAt,
            updatedAt: collection.updatedAt,
            sortIndex: collection.sortIndex,
            isPinned: collection.isPinned
        )
        context.insert(model)
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func update(_ collection: Collection) async throws {
        let id = collection.id
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.title = collection.title
        model.iconName = collection.iconName
        model.colorToken = collection.colorToken
        model.updatedAt = collection.updatedAt
        model.sortIndex = collection.sortIndex
        model.isPinned = collection.isPinned
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }
}
