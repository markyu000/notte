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

extension NodeMutationService {
    func delete(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("开始删除节点, nodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let descendants = queryService.descendants(of: nodeID, in: nodes)
        let allIDs = [nodeID] + descendants.map(\.id)
        for id in allIDs {
            try await blockRepository.deleteAll(in: id)
            try await nodeRepository.delete(by: id)
        }
        logger.info("节点删除成功, nodeID=\(nodeID), 共 \(allIDs.count) 个", function: #function)
    }
}

extension NodeMutationService {
    func moveUp(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("上移节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let prev = queryService.previousSibling(of: nodeID, in: nodes) else { return }

        var updatedNode = node
        var updatedPrev = prev
        updatedNode.sortIndex = prev.sortIndex
        updatedPrev.sortIndex = node.sortIndex
        updatedNode.updatedAt = Date()
        updatedPrev.updatedAt = Date()

        try await nodeRepository.update(updatedNode)
        try await nodeRepository.update(updatedPrev)
        logger.info("节点上移成功, nodeID=\(nodeID)", function: #function)
    }

    func moveDown(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("下移节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let next = queryService.nextSibling(of: nodeID, in: nodes) else { return }

        var updatedNode = node
        var updatedNext = next
        updatedNode.sortIndex = next.sortIndex
        updatedNext.sortIndex = node.sortIndex
        updatedNode.updatedAt = Date()
        updatedNext.updatedAt = Date()

        try await nodeRepository.update(updatedNode)
        try await nodeRepository.update(updatedNext)
        logger.info("节点下移成功, nodeID=\(nodeID)", function: #function)
    }
}

extension NodeMutationService {
    func indent(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("缩进节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let newParent = queryService.previousSibling(of: nodeID, in: nodes) else { return }

        let existingChildren = queryService.children(of: newParent.id, in: nodes)
        let lastIndex = existingChildren.map(\.sortIndex).max()
        let newSortIndex = lastIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        var updatedNode = node
        updatedNode.parentNodeID = newParent.id
        updatedNode.depth = newParent.depth + 1
        updatedNode.sortIndex = newSortIndex
        updatedNode.updatedAt = Date()
        try await nodeRepository.update(updatedNode)

        let descendants = queryService.descendants(of: nodeID, in: nodes)
        for var desc in descendants {
            desc.depth += 1
            desc.updatedAt = Date()
            try await nodeRepository.update(desc)
        }
        logger.info("节点缩进成功, nodeID=\(nodeID)", function: #function)
    }

    func outdent(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("反缩进节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let parentNode = queryService.parent(of: nodeID, in: nodes) else { return }

        let nextOfParent = queryService.nextSibling(of: parentNode.id, in: nodes)
        let newSortIndex: Double
        if let next = nextOfParent {
            newSortIndex = SortIndexPolicy.indexBetween(before: parentNode.sortIndex, after: next.sortIndex)
        } else {
            newSortIndex = SortIndexPolicy.indexAfter(last: parentNode.sortIndex)
        }

        var updatedNode = node
        updatedNode.parentNodeID = parentNode.parentNodeID
        updatedNode.depth = max(0, node.depth - 1)
        updatedNode.sortIndex = newSortIndex
        updatedNode.updatedAt = Date()
        try await nodeRepository.update(updatedNode)

        let descendants = queryService.descendants(of: nodeID, in: nodes)
        for var desc in descendants {
            desc.depth = max(0, desc.depth - 1)
            desc.updatedAt = Date()
            try await nodeRepository.update(desc)
        }
        logger.info("节点反缩进成功, nodeID=\(nodeID)", function: #function)
    }
}
