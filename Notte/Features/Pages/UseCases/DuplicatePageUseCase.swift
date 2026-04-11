//
//  DuplicatePageUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct DuplicatePageUseCase {
    let repository: PageRepositoryProtocol
    private let logger = ConsoleLogger()

    @discardableResult
    func execute(pageID: UUID) async throws -> Page {
        logger.debug("开始复制 Page, id=\(pageID)", function: #function)
        guard let original = try await repository.fetch(by: pageID) else {
            logger.error("Page 未找到, id=\(pageID)", function: #function)
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
        logger.info("Page 复制成功, newId=\(duplicate.id), title=\(duplicate.title)", function: #function)
        return duplicate
    }
}