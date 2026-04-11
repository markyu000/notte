//
//  ReorderPagesUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct ReorderPagesUseCase {
    let repository: PageRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(collectionID: UUID, moving id: UUID, after targetID: UUID?) async throws {
        logger.debug("重排 Page, id=\(id), after=\(String(describing: targetID))", function: #function)
        let all = try await repository.fetchAll(in: collectionID)
            .sorted { $0.sortIndex < $1.sortIndex }

        let firstSortIndex = all.first?.sortIndex

        let targetIndex = targetID.flatMap { tid in
            all.firstIndex { $0.id == tid }
        }

        let lower: Double? = targetIndex.map { all[$0].sortIndex }
        let upper: Double? = targetIndex.flatMap { idx in
            all.indices.contains(idx + 1) ? all[idx + 1].sortIndex : nil
        }
        
        let newIndex: Double!
        switch (lower, upper) {
        case (nil, nil):
            if let firstSortIndex {
                newIndex = SortIndexPolicy.indexBetween(before: 0, after: firstSortIndex)
            } else {
                newIndex = SortIndexPolicy.initialIndex()
            }
        case (nil, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: 0, after: u)
        case (let l?, nil):
            newIndex = SortIndexPolicy.indexAfter(last: l)
        case (let l?, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: l, after: u)
        }

        guard var page = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        page.sortIndex = newIndex
        page.updatedAt = Date()
        try await repository.update(page)
        logger.info("Page 重排成功, id=\(id), newIndex=\(newIndex!)", function: #function)

        Task.detached {
            let latest = try await repository.fetchAll(in: collectionID)
            try await SortIndexNormalizer.normalizeIfNeeded(latest) { updated in
                try await repository.update(updated)
            }
        }
    }
}