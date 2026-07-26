//
//  BlockEditingService.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import Foundation

/// 负责 Block 内容层的增删改排操作。
/// MVP 阶段只处理 .text 类型，POST 阶段扩展类型时在此添加逻辑。
struct BlockEditingService {

    let blockRepository: BlockRepositoryProtocol
    private let logger = ConsoleLogger()

    func addBlock(nodeID: UUID, type: BlockType) async throws -> Block {
        logger.debug("开始添加 Block, nodeID=\(nodeID), type=\(type)", function: #function)
        let existing = try await blockRepository.fetchAll(in: nodeID)
        let lastIndex = existing.map(\.sortIndex).max()
        let newSortIndex = lastIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        let block = Block(
            id: UUID(), nodeID: nodeID, type: type,
            content: "", sortIndex: newSortIndex,
            createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(block)
        logger.info("Block 添加成功, id=\(block.id)", function: #function)
        return block
    }

    func deleteBlock(blockID: UUID) async throws {
        logger.debug("开始删除 Block, blockID=\(blockID)", function: #function)
        try await blockRepository.delete(by: blockID)
        logger.info("Block 删除成功, blockID=\(blockID)", function: #function)
    }

    func updateContent(blockID: UUID, content: String) async throws {
        logger.debug("更新 Block 内容, blockID=\(blockID)", function: #function)
        guard var block = try await blockRepository.fetch(by: blockID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        block.content = content
        block.updatedAt = Date()
        try await blockRepository.update(block)
        logger.info("Block 内容更新成功, blockID=\(blockID)", function: #function)
    }
}

extension BlockEditingService {
    /// 与同节点内前一个 Block 互换 sortIndex（朴素一维上移）。
    func moveUp(blockID: UUID) async throws {
        try await swapWithNeighbor(blockID: blockID, offset: -1)
    }

    /// 与同节点内后一个 Block 互换 sortIndex（朴素一维下移）。
    func moveDown(blockID: UUID) async throws {
        try await swapWithNeighbor(blockID: blockID, offset: 1)
    }

    /// 在同节点的 Block 列表中，将目标块与相邻块互换 sortIndex。
    /// offset = -1 与前一个互换，+1 与后一个互换；越界则静默返回。
    private func swapWithNeighbor(blockID: UUID, offset: Int) async throws {
        logger.debug("块移动, blockID=\(blockID), offset=\(offset)", function: #function)
        guard let block = try await blockRepository.fetch(by: blockID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        let siblings = try await blockRepository.fetchAll(in: block.nodeID)
            .sorted { $0.sortIndex < $1.sortIndex }
        guard let index = siblings.firstIndex(where: { $0.id == blockID }) else { return }
        let neighborIndex = index + offset
        guard siblings.indices.contains(neighborIndex) else { return }

        var current = siblings[index]
        var neighbor = siblings[neighborIndex]
        let currentSortIndex = current.sortIndex
        current.sortIndex = neighbor.sortIndex
        neighbor.sortIndex = currentSortIndex
        current.updatedAt = Date()
        neighbor.updatedAt = Date()

        try await blockRepository.update(current)
        try await blockRepository.update(neighbor)
        logger.info("块移动成功, blockID=\(blockID)", function: #function)
    }

    func reorderBlock(blockID: UUID, after targetID: UUID?) async throws {
        logger.debug("调整 Block 排序, blockID=\(blockID), after=\(String(describing: targetID))", function: #function)
        guard var block = try await blockRepository.fetch(by: blockID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }

        var (lower, upper, firstSortIndex) = try await neighborIndexes(nodeID: block.nodeID, targetID: targetID)

        if let l = lower, let u = upper, SortIndexPolicy.needsNormalization(before: l, after: u) {
            try await blockRepository.normalizeSortIndexesIfNeeded(in: block.nodeID)
            (lower, upper, firstSortIndex) = try await neighborIndexes(nodeID: block.nodeID, targetID: targetID)
            if let l2 = lower, let u2 = upper {
                assert(
                    !SortIndexPolicy.needsNormalization(before: l2, after: u2),
                    "归一化后间隙仍然过小，normalize 或 scope 可能有 bug"
                )
            }
        }

        let newSortIndex = SortIndexPolicy.indexForReorder(lower: lower, upper: upper, firstSortIndex: firstSortIndex)
        block.sortIndex = newSortIndex
        block.updatedAt = Date()
        try await blockRepository.update(block)

        logger.info("Block 排序更新成功, blockID=\(blockID), newSortIndex=\(newSortIndex)", function: #function)
    }

    private func neighborIndexes(
        nodeID: UUID,
        targetID: UUID?
    ) async throws -> (lower: Double?, upper: Double?, firstSortIndex: Double?) {
        let all = try await blockRepository.fetchAll(in: nodeID)
            .sorted { $0.sortIndex < $1.sortIndex }
        let targetIndex = targetID.flatMap { tid in all.firstIndex { $0.id == tid } }
        let lower: Double? = targetIndex.map { all[$0].sortIndex }
        let upper: Double? = targetIndex.flatMap { idx in
            all.indices.contains(idx + 1) ? all[idx + 1].sortIndex : nil
        }
        return (lower, upper, all.first?.sortIndex)
    }
}
