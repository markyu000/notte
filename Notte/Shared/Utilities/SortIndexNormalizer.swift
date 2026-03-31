//
//  SortIndexNormalizer.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/31.
//

import Foundation

struct SortIndexNormalizer {
    static func normalizeIfNeeded(
        _ collecitons: [Collection],
        update: (Collection) async throws -> Void
    ) async throws {
        let sorted = collecitons.sorted { $0.sortIndex < $1.sortIndex }

        let needsNorm = zip(sorted, sorted.dropFirst()).contains { a, b in
            SortIndexPolicy
                .needsNormalization(before: a.sortIndex, after: b.sortIndex)
        }

        guard needsNorm else { return }

        let newIndexes = SortIndexPolicy.normalize(count: sorted.count)
        for (collection, newIndex) in zip(sorted, newIndexes) {
            var updated = collection
            updated.sortIndex = newIndex
            updated.updatedAt = Date()
            try await update(updated)
        }
    }
}
