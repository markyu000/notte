//
//  NodePersistenceCoordinator.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import Foundation

/// 管理 Node 编辑器的自动保存策略。
/// UI 层高频触发的内容变更（如逐字输入）通过此类的 debounce 机制
/// 延迟合并后再写入 Repository，避免每次击键都触发存储操作。
@MainActor
class NodePersistenceCoordinator {

    enum SaveState {
        case saved
        case saving
        case unsaved
    }

    private(set) var saveState: SaveState = .saved

    private let engine: NodeEditorEngine
    private var pendingBlockUpdates: [UUID: String] = [:]
    private var pendingTitleUpdates: [UUID: String] = [:]
    private var debounceTask: Task<Void, Never>?

    private let debounceInterval: Duration = .milliseconds(600)

    init(engine: NodeEditorEngine) {
        self.engine = engine
    }

    // MARK: - 触发延迟保存

    func scheduleContentUpdate(blockID: UUID, content: String) {
        pendingBlockUpdates[blockID] = content
        saveState = .unsaved
        scheduleFlush()
    }

    func scheduleTitleUpdate(nodeID: UUID, title: String) {
        pendingTitleUpdates[nodeID] = title
        saveState = .unsaved
        scheduleFlush()
    }

    private func scheduleFlush() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            await flush()
        }
    }

    // MARK: - 强制立即保存（退出/后台时调用）

    func flush() async {
        debounceTask?.cancel()
        guard !pendingBlockUpdates.isEmpty || !pendingTitleUpdates.isEmpty else {
            saveState = .saved
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
            } else {
                saveState = .unsaved
            }
        } catch {
            engine.error = .repositoryError(error as? RepositoryError ?? RepositoryError.saveFailed(error))
            saveState = .unsaved
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
