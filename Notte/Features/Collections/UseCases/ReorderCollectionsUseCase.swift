//
//  ReorderCollectionsUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/30.
//

import Foundation

struct ReorderCollectionsUseCase {
    let repository: CollectionRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(moving id: UUID, after targetID: UUID?) async throws {
        logger.debug("重排 Collection, id=\(id), after=\(String(describing: targetID))", function: #function)

        var (lower, upper, firstSortIndex) = try await neighborIndexes(targetID: targetID)

        if let l = lower, let u = upper, SortIndexPolicy.needsNormalization(before: l, after: u) {
            try await repository.normalizeSortIndexesIfNeeded()
            (lower, upper, firstSortIndex) = try await neighborIndexes(targetID: targetID)
            if let l2 = lower, let u2 = upper {
                assert(
                    !SortIndexPolicy.needsNormalization(before: l2, after: u2),
                    "归一化后间隙仍然过小，normalize 或 scope 可能有 bug"
                )
            }
        }

        let newIndex = SortIndexPolicy.indexForReorder(lower: lower, upper: upper, firstSortIndex: firstSortIndex)

        guard var collection = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        collection.sortIndex = newIndex
        collection.updatedAt = Date()
        try await repository.update(collection)
        logger.info("Collection 重排成功, id=\(id), newIndex=\(newIndex)", function: #function)
    }

    private func neighborIndexes(
        targetID: UUID?
    ) async throws -> (lower: Double?, upper: Double?, firstSortIndex: Double?) {
        let all = try await repository.fetchAll()
            .sorted { $0.sortIndex < $1.sortIndex }
        let targetIndex = targetID.flatMap { tid in all.firstIndex { $0.id == tid } }
        let lower: Double? = targetIndex.map { all[$0].sortIndex }
        let upper: Double? = targetIndex.flatMap { idx in
            all.indices.contains(idx + 1) ? all[idx + 1].sortIndex : nil
        }
        return (lower, upper, all.first?.sortIndex)
    }
}
