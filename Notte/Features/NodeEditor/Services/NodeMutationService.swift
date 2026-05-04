import Foundation

/// 负责执行 Node 结构变更操作。
/// 每个方法都会直接读写 Repository，调用方无需手动持久化。
struct NodeMutationService {

    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    let queryService: NodeQueryService
    private let logger = ConsoleLogger()

    // MARK: - 插入

    func insertTopLevel(in pageID: UUID) async throws -> Node {
        logger.debug("开始插入顶级节点, pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let topLevelNodes = nodes.filter { $0.parentNodeID == nil }
        let newSortIndex = topLevelNodes.map(\.sortIndex).max().map {
            SortIndexPolicy.indexAfter(last: $0)
        } ?? SortIndexPolicy.initialIndex()

        let newNode = Node(
            id: UUID(),
            pageID: pageID,
            parentNodeID: nil,
            title: "",
            depth: 0,
            sortIndex: newSortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        let emptyBlock = Block(
            id: UUID(),
            nodeID: newNode.id,
            type: .text,
            content: "",
            sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(),
            updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)

        logger.info("顶级节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }

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
            id: UUID(),
            pageID: pageID,
            parentNodeID: current.parentNodeID,
            title: "",
            depth: current.depth,
            sortIndex: newSortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        // 自动为新节点创建一个空 text Block
        let emptyBlock = Block(
            id: UUID(),
            nodeID: newNode.id,
            type: .text,
            content: "",
            sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(),
            updatedAt: Date()
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
            id: UUID(),
            pageID: pageID,
            parentNodeID: nodeID,
            title: "",
            depth: parentNode.depth + 1,
            sortIndex: newSortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        let emptyBlock = Block(
            id: UUID(),
            nodeID: newNode.id,
            type: .text,
            content: "",
            sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(),
            updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)

        logger.info("子节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }

    // MARK: - 删除

    func delete(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("开始删除节点, nodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        // 1. 找到全部子孙节点 id（不含自身）
        let descendants = queryService.descendants(of: nodeID, in: nodes)
        let allIDs = [nodeID] + descendants.map(\.id)
        // 2. 每个节点先删其 Block，再删节点本身
        for id in allIDs {
            try await blockRepository.deleteAll(in: id)
            try await nodeRepository.delete(by: id)
        }
        logger.info("节点删除成功, nodeID=\(nodeID), 共 \(allIDs.count) 个", function: #function)
    }

    // MARK: - 移动

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

    // MARK: - 缩进 / 反缩进

    func indent(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("缩进节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let newParent = queryService.previousSibling(of: nodeID, in: nodes) else {
            // 没有前一个同级节点，无法缩进
            return
        }

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

        // 批量更新所有子孙节点的 depth +1
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
        guard let parentNode = queryService.parent(of: nodeID, in: nodes) else {
            // 已在根层，无法反缩进
            return
        }

        let nextOfParent = queryService.nextSibling(of: parentNode.id, in: nodes)
        let newSortIndex: Double
        if let next = nextOfParent {
            newSortIndex = SortIndexPolicy.indexBetween(
                before: parentNode.sortIndex,
                after: next.sortIndex
            )
        } else {
            newSortIndex = SortIndexPolicy.indexAfter(last: parentNode.sortIndex)
        }

        var updatedNode = node
        updatedNode.parentNodeID = parentNode.parentNodeID
        updatedNode.depth = max(0, node.depth - 1)
        updatedNode.sortIndex = newSortIndex
        updatedNode.updatedAt = Date()
        try await nodeRepository.update(updatedNode)

        // 批量更新所有子孙节点的 depth -1
        let descendants = queryService.descendants(of: nodeID, in: nodes)
        for var desc in descendants {
            desc.depth = max(0, desc.depth - 1)
            desc.updatedAt = Date()
            try await nodeRepository.update(desc)
        }
        logger.info("节点反缩进成功, nodeID=\(nodeID)", function: #function)
    }

    // MARK: - 折叠

    func toggleCollapse(nodeID: UUID) async throws {
        logger.debug("切换折叠状态, nodeID=\(nodeID)", function: #function)
        guard var node = try await nodeRepository.fetch(by: nodeID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        node.isCollapsed.toggle()
        node.updatedAt = Date()
        try await nodeRepository.update(node)
        logger.info("折叠状态更新成功, nodeID=\(nodeID)", function: #function)
    }

    // MARK: - 标题

    func updateTitle(nodeID: UUID, title: String) async throws {
        logger.debug("更新节点标题, nodeID=\(nodeID)", function: #function)
        guard var node = try await nodeRepository.fetch(by: nodeID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        node.title = title
        node.updatedAt = Date()
        try await nodeRepository.update(node)
        logger.info("节点标题更新成功, nodeID=\(nodeID)", function: #function)
    }
    
    func insertFirst(in pageID: UUID) async throws -> Node {
        try await insertTopLevel(in: pageID)
    }
}
