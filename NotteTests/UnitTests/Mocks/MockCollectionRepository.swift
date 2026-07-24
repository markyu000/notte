//
//  MockCollectionRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/5.
//

import Foundation
@testable import Notte

@MainActor
class MockCollectionRepository: CollectionRepositoryProtocol {
    var storedCollections: [Collection] = []
    var shouldThrowOnCreate = false
    var shouldThrowOnNormalize = false
    var normalizeCallCount = 0
    
    func fetchAll() async throws -> [Collection] {
        storedCollections
    }
    
    func fetch(by id: UUID) async throws -> Collection? {
        storedCollections.first { $0.id == id }
    }
    
    func create(_ collection: Collection) async throws {
        if shouldThrowOnCreate {
            throw RepositoryError.saveFailed(NSError(domain: "MockCollectionRepository", code: -1))
        }
        storedCollections.append(collection)
    }
    
    func update(_ collection: Collection) async throws {
        guard let index = storedCollections.firstIndex(where: {$0.id == collection.id}) else {
            throw RepositoryError.notFound
        }
        storedCollections[index] = collection
    }
    
    func delete(by id: UUID) async throws {
        guard let index = storedCollections.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        storedCollections.remove(at: index)
    }

    /// 忠实复现真实归一化：跑域层 SortIndexNormalizer 并写回。
    func normalizeSortIndexesIfNeeded() async throws {
        normalizeCallCount += 1
        if shouldThrowOnNormalize {
            throw RepositoryError.saveFailed(NSError(domain: "MockCollectionRepository", code: -2))
        }
        try await SortIndexNormalizer.normalizeIfNeeded(storedCollections) { updated in
            if let index = storedCollections.firstIndex(where: { $0.id == updated.id }) {
                storedCollections[index] = updated
            }
        }
    }
}
