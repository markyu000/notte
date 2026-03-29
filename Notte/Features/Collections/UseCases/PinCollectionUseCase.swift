//
//  PinCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct PinCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(id: UUID) async throws {
        guard var entity = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        entity.isPinned.toggle()
        entity.updatedAt = Date()
        try await repository.update(entity)
    }
}
