//
//  SortIndexNormalizationActor.swift
//  Notte
//
//  Created by 余哲源 on 2026/7/19.
//

import Foundation
import SwiftData

@ModelActor
actor SortIndexNormalizationActor {

    // MARK: - 共享核心（对所有 @Model 类型通用，新增类型不用再写这段）

    private func normalizeAndSave<Model: SortIndexPersistable>(
        _ models: [Model] 
    ) async throws {
        let byID = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
        let domainItems = models.map { $0.toDomain() }
        try await SortIndexNormalizer.normalizeIfNeeded(domainItems) { updated in
            guard let model = byID[updated.id] else { return }
            model.sortIndex = updated.sortIndex
            model.updatedAt = updated.updatedAt
        }
        try modelContext.save()
    }

    // MARK: - 各类型专属入口（只负责 fetch，逻辑到此为止就转交给共享核心）

    func normalizePages(in collectionID: UUID) async throws {
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.collectionID == collectionID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        try await normalizeAndSave(try modelContext.fetch(descriptor))
    }

    func normalizeCollections() async throws {
        let descriptor = FetchDescriptor<CollectionModel>(sortBy: [SortDescriptor(\.sortIndex)])
        try await normalizeAndSave(try modelContext.fetch(descriptor))
    }

    func normalizeNodes(in pageID: UUID, parentNodeID: UUID?) async throws {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.pageID == pageID && $0.parentNodeID == parentNodeID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        try await normalizeAndSave(try modelContext.fetch(descriptor))
    }
    
    func normalizeBlocks(in nodeID: UUID) async throws {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.nodeID == nodeID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        try await normalizeAndSave(try modelContext.fetch(descriptor))
    }
}

extension SortIndexNormalizationActor {
    // #Preview 宏展开的上下文里直接调用 @ModelActor 合成的 init 会报
    // "no accessible initializers"（宏套宏的已知限制），套一层普通静态方法绕开。
    static func preview(container: ModelContainer) -> SortIndexNormalizationActor {
        SortIndexNormalizationActor(modelContainer: container)
    }
}
