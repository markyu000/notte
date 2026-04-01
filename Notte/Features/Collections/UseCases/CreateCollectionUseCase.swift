//
//  CreateCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct CreateCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    @discardableResult
    func execute(title: String) async throws -> Collection {
        let all = try await repository.fetchAll()
        let maxIndex = all.map(\.sortIndex).max() ?? 0
        let entity = Collection(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: maxIndex + 1000,
            isPinned: false,
        )
        try await repository.create(entity)
        return entity
    }
}
