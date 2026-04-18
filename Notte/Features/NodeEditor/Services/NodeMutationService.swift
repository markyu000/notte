//
//  NodeMutationService.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/18.
//

import Foundation

/// 负责执行 Node 结构变更操作。
/// 每个方法都会直接读写 Repository，调用方无需手动持久化。
struct NodeMutationService {

    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    let queryService: NodeQueryService
    private let logger = ConsoleLogger()

    // MARK: - 插入

    func insertAfter(nodeID: UUID, in pageID: UUID) async throws -> Node {
        logger.debug("开始在节点后插入, nodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let current = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        let nextSibling = queryService.nextSibling(of: nodeID, in: nodes)
        let newSortIndex: Double
        if let next = nextSibling {
            newSortIndex = SortIndexPolicy.indexBetween(before: current.sortIndex, after: next.sortIndex)
        } else {
            newSortIndex = SortIndexPolicy.indexAfter(last: current.sortIndex)
        }

        let newNode = Node(
            id: UUID(), pageID: pageID,
            parentNodeID: current.parentNodeID,
            title: "", depth: current.depth,
            sortIndex: newSortIndex, isCollapsed: false,
            createdAt: Date(), updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        let emptyBlock = Block(
            id: UUID(), nodeID: newNode.id, type: .text,
            content: "", sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)
        logger.info("节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }

    func insertChild(nodeID: UUID, in pageID: UUID) async throws -> Node {
        logger.debug("开始插入子节点, parentNodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let parentNode = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        let existingChildren = queryService.children(of: nodeID, in: nodes)
        let lastChildIndex = existingChildren.map(\.sortIndex).max()
        let newSortIndex = lastChildIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        let newNode = Node(
            id: UUID(), pageID: pageID,
            parentNodeID: nodeID,
            title: "", depth: parentNode.depth + 1,
            sortIndex: newSortIndex, isCollapsed: false,
            createdAt: Date(), updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        let emptyBlock = Block(
            id: UUID(), nodeID: newNode.id, type: .text,
            content: "", sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)
        logger.info("子节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }
}
