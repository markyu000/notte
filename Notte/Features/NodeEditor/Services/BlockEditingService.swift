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
