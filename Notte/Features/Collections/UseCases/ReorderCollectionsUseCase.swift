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
        let all = try await repository.fetchAll()
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
            // 移动到最前面：用 (0 + 当前第一项sortIndex)/2，避免出现与第一项相同的 sortIndex。
            // 例如当前第一项是 1000，则新值是 500。
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
        
        guard var collection = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        collection.sortIndex = newIndex
        collection.updatedAt = Date()
        try await repository.update(collection)
        logger.info("Collection 重排成功, id=\(id), newIndex=\(newIndex!)", function: #function)

        Task.detached {
            let latest = try await repository.fetchAll()
            try await SortIndexNormalizer.normalizeIfNeeded(latest) { updated in
                try await repository.update(updated)
            }
        }
    }
}

