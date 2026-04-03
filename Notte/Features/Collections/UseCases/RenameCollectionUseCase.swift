//
//  RenameCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct RenameCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(id: UUID, newTitle: String) async throws {
        guard var collection = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        collection.title = newTitle
        collection.updatedAt = Date()
        try await repository.update(collection)
    }
}
