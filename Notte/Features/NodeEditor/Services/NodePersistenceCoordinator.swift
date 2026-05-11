//
//  NodePersistenceCoordinator.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import Foundation
import Combine

/// 管理 Node 编辑器的自动保存策略。
/// UI 层高频触发的内容变更先暂存为未保存状态，
/// 由显式保存或页面退出/后台时统一写入 Repository。
@MainActor
class NodePersistenceCoordinator: ObservableObject {

    enum SaveState {
        case saved
        case saving
        case unsaved
    }

    @Published private(set) var saveState: SaveState = .saved
    @Published private(set) var hasUnsavedChanges = false

    private let engine: NodeEditorEngine
    private var pendingBlockUpdates: [UUID: String] = [:]
    private var pendingTitleUpdates: [UUID: String] = [:]

    init(engine: NodeEditorEngine) {
        self.engine = engine
    }

    // MARK: - 标记待保存

    func scheduleContentUpdate(blockID: UUID, content: String) {
        pendingBlockUpdates[blockID] = content
        hasUnsavedChanges = true
        saveState = .unsaved
    }

    func scheduleTitleUpdate(nodeID: UUID, title: String) {
        pendingTitleUpdates[nodeID] = title
        hasUnsavedChanges = true
        saveState = .unsaved
    }

    func markStructuralChange() {
        hasUnsavedChanges = true
        if saveState == .saved {
            saveState = .unsaved
        }
    }

    // MARK: - 强制立即保存（按钮/退出/后台时调用）

    func flush() async {
        guard !pendingBlockUpdates.isEmpty || !pendingTitleUpdates.isEmpty else {
            saveState = .saved
            hasUnsavedChanges = false
            return
        }

        let blockUpdatesSnapshot = pendingBlockUpdates
        let titleUpdatesSnapshot = pendingTitleUpdates
        saveState = .saving

        do {
            try await persist(blockUpdates: blockUpdatesSnapshot, titleUpdates: titleUpdatesSnapshot)
            clearPersistedSnapshots(
                blockUpdates: blockUpdatesSnapshot,
                titleUpdates: titleUpdatesSnapshot
            )

            if pendingBlockUpdates.isEmpty && pendingTitleUpdates.isEmpty {
                saveState = .saved
                hasUnsavedChanges = false
            } else {
                saveState = .unsaved
                hasUnsavedChanges = true
            }
        } catch {
            engine.error = .repositoryError(error as? RepositoryError ?? RepositoryError.saveFailed(error))
            saveState = .unsaved
            hasUnsavedChanges = true
        }
    }
}

private extension NodePersistenceCoordinator {
    func persist(
        blockUpdates: [UUID: String],
        titleUpdates: [UUID: String]
    ) async throws {
        for (blockID, content) in blockUpdates {
            guard var block = try await engine.blockRepository.fetch(by: blockID) else {
                throw RepositoryError.notFound
            }
            block.content = content
            block.updatedAt = Date()
            try await engine.blockRepository.update(block)
        }

        for (nodeID, title) in titleUpdates {
            guard var node = try await engine.nodeRepository.fetch(by: nodeID) else {
                throw RepositoryError.notFound
            }
            node.title = title
            node.updatedAt = Date()
            try await engine.nodeRepository.update(node)
        }
    }

    func clearPersistedSnapshots(
        blockUpdates: [UUID: String],
        titleUpdates: [UUID: String]
    ) {
        for (blockID, content) in blockUpdates where pendingBlockUpdates[blockID] == content {
            pendingBlockUpdates.removeValue(forKey: blockID)
        }

        for (nodeID, title) in titleUpdates where pendingTitleUpdates[nodeID] == title {
            pendingTitleUpdates.removeValue(forKey: nodeID)
        }
    }
}
