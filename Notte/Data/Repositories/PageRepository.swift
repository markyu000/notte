//
//  PageRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class PageRepository: PageRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in collectionID: UUID) async throws -> [Page] {
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.collectionID == collectionID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        do {
            let models = try context.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func fetch(by id: UUID) async throws -> Page? {
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.id == id }
        )
        do {
            return try context.fetch(descriptor).first?.toDomain()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func create(_ page: Page) async throws {
        let model = PageModel(
            id: page.id,
            collectionID: page.collectionID,
            title: page.title,
            createdAt: page.createdAt,
            updatedAt: page.updatedAt,
            sortIndex: page.sortIndex,
            isArchived: page.isArchived
        )
        context.insert(model)
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func update(_ page: Page) async throws {
        let id = page.id
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.title = page.title
        model.updatedAt = page.updatedAt
        model.sortIndex = page.sortIndex
        model.isArchived = page.isArchived
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<PageModel>(
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
