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

        var (lower, upper, firstSortIndex) = try await neighborIndexes(collectionID: collectionID, targetID: targetID)

        if let l = lower, let u = upper, SortIndexPolicy.needsNormalization(before: l, after: u) {
            try await repository.normalizeSortIndexesIfNeeded(in: collectionID)
            (lower, upper, firstSortIndex) = try await neighborIndexes(collectionID: collectionID, targetID: targetID)
            if let l2 = lower, let u2 = upper {
                assert(
                    !SortIndexPolicy.needsNormalization(before: l2, after: u2),
                    "归一化后间隙仍然过小，normalize 或 scope 可能有 bug"
                )
            }
        }

        let newIndex = SortIndexPolicy.indexForReorder(lower: lower, upper: upper, firstSortIndex: firstSortIndex)

        guard var page = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        page.sortIndex = newIndex
        page.updatedAt = Date()
        try await repository.update(page)
        logger.info("Page 重排成功, id=\(id), newIndex=\(newIndex)", function: #function)
    }

    private func neighborIndexes(
        collectionID: UUID,
        targetID: UUID?
    ) async throws -> (lower: Double?, upper: Double?, firstSortIndex: Double?) {
        let all = try await repository.fetchAll(in: collectionID)
            .sorted { $0.sortIndex < $1.sortIndex }
        let targetIndex = targetID.flatMap { tid in all.firstIndex { $0.id == tid } }
        let lower: Double? = targetIndex.map { all[$0].sortIndex }
        let upper: Double? = targetIndex.flatMap { idx in
            all.indices.contains(idx + 1) ? all[idx + 1].sortIndex : nil
        }
        return (lower, upper, all.first?.sortIndex)
    }
}
