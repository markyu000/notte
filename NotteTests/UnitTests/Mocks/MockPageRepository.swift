//
//  MockPageRepository.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import Foundation
@testable import Notte

@MainActor
class MockPageRepository: PageRepositoryProtocol {

    var storedPages: [Page] = []
    var shouldThrowOnCreate = false
    var shouldThrowOnNormalize = false
    var normalizeCallCount = 0

    func fetchAll(in collectionID: UUID) async throws -> [Page] {
        storedPages.filter { $0.collectionID == collectionID }
    }

    func fetch(by id: UUID) async throws -> Page? {
        storedPages.first { $0.id == id }
    }

    func create(_ page: Page) async throws {
        if shouldThrowOnCreate { throw RepositoryError.saveFailed(NSError(domain: "MockPageRepository", code: -1)) }
        storedPages.append(page)
    }

    func update(_ page: Page) async throws {
        guard let index = storedPages.firstIndex(where: { $0.id == page.id }) else {
            throw RepositoryError.notFound
        }
        storedPages[index] = page
    }

    func delete(by id: UUID) async throws {
        guard let index = storedPages.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        storedPages.remove(at: index)
    }

    /// 忠实复现真实归一化：按 scope 过滤后跑域层 SortIndexNormalizer 并写回。
    func normalizeSortIndexesIfNeeded(in collectionID: UUID) async throws {
        normalizeCallCount += 1
        if shouldThrowOnNormalize {
            throw RepositoryError.saveFailed(NSError(domain: "MockPageRepository", code: -2))
        }
        let scoped = storedPages.filter { $0.collectionID == collectionID }
        try await SortIndexNormalizer.normalizeIfNeeded(scoped) { updated in
            if let index = storedPages.firstIndex(where: { $0.id == updated.id }) {
                storedPages[index] = updated
            }
        }
    }
}
