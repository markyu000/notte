//
//  DuplicatePageUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct DuplicatePageUseCase {
    let repository: PageRepositoryProtocol

    @discardableResult
    func execute(pageID: UUID) async throws -> Page {
        guard let original = try await repository.fetch(by: pageID) else {
            throw AppError.repositoryError(.notFound)
        }

        let existing = try await repository.fetchAll(in: original.collectionID)
        let maxIndex = existing.map(\.sortIndex).max() ?? 0

        let duplicate = Page(
            id: UUID(),
            collectionID: original.collectionID,
            title: "\(original.title) 副本",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: maxIndex + 1000,
            isArchived: false
        )
        try await repository.create(duplicate)
        return duplicate
    }
}