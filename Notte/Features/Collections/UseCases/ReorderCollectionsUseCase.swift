//
//  ReorderCollectionsUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/30.
//

import Foundation

struct ReorderCollectionsUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(moving id: UUID, after targetID: UUID?) async throws {
        let all = try await repository.fetchAll()
            .sorted { $0.sortIndex < $1.sortIndex }

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
            newIndex = SortIndexPolicy.initialIndex()
        case (nil, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: 0, after: u)
        case (let l?, nil):
            newIndex = SortIndexPolicy.indexAfter(last: l)
        case (let l?, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: l, after: u)
        }
        
        guard var collection = try repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        collection.sortIndex = newIndex
        collection.updatedAt = Date()
        try await repository.update(collection)

        Task.detached {
            let latest = try await repository.fetchAll()
            try await SortIndexNormalizer.normalizeIfNeeded(latest) { updated in
                try await repository.update(updated)
            }
        }
    }
}

