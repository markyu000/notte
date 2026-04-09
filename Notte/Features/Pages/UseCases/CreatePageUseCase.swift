//
//  CreatePageUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct CreatePageUseCase {
    let repository: PageRepositoryProtocol

    @discardableResult
    func execute(title: String, in collectionID: UUID) async throws -> Page {
        let existing = try await repository.fetchAll(in: collectionID)
        let maxIndex = existing.map(\.sortIndex).max() ?? 0

        let page = Page(
            id: UUID(),
            collectionID: collectionID,
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: maxIndex + 1000,
            isArchived: false
        )
        try await repository.create(page)
        return page
    }
}