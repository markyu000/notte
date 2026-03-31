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

        let newIndex = insertSortIndex(between: lower, and: upper)
        guard var collection = try repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        collection.sortIndex = newIndex
        collection.updatedAt = Date()
        try repository.update(collection)
    }

    func insertSortIndex(between lower: Double?, and upper: Double?) -> Double {
        switch (lower, upper) {
        case (nil, nil):       return 1000.0           // 列表为空
        case (nil, let u?):    return u / 2.0          // 插到最前
        case (let l?, nil):    return l + 1000.0       // 插到最后
        case (let l?, let u?): return (l + u) / 2.0    // 插到中间
        }
    }
}

