//
//  SortIndexSyncGuardRailTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/7/25.
//
//  覆盖 #303：sortIndex 同步护栏。
//  在真正计算新 sortIndex 的调用点，若相邻邻居间隙已 < minimumGap，
//  则先同步强制归一化、重新计算，保证永远不会铸出重复 / 不稳定的 sortIndex。
//  归一化持续失败时，错误应沿主操作向上传播，且不留下任何半成品状态。
//

import XCTest
@testable import Notte

@MainActor
final class SortIndexSyncGuardRailTests: XCTestCase {

    // MARK: - Pages（ReorderPagesUseCase）

    /// 相邻 Page 间隙过小时，reorder 触发同步护栏：归一化被调用一次，
    /// 移动后的 Page 落在目标之后，且全体 sortIndex 唯一、严格有序。
    func test_pages_reorder_triggersGuardRail_noDuplicateSortIndex() async throws {
        let repository = MockPageRepository()
        let useCase = ReorderPagesUseCase(repository: repository)
        let collectionID = UUID()

        // page1 与 page2 之间间隙 0.0005 < minimumGap(0.001)，强制触发护栏
        let page1 = makePage(collectionID: collectionID, sortIndex: 1000)
        let page2 = makePage(collectionID: collectionID, sortIndex: 1000.0005)
        let page3 = makePage(collectionID: collectionID, sortIndex: 5000)
        repository.storedPages = [page1, page2, page3]

        try await useCase.execute(collectionID: collectionID, moving: page3.id, after: page1.id)

        XCTAssertEqual(repository.normalizeCallCount, 1, "间隙过小应触发一次同步归一化")

        let all = try await repository.fetchAll(in: collectionID).sorted { $0.sortIndex < $1.sortIndex }
        assertStrictlyAscendingUnique(all.map(\.sortIndex))
        // page3 应落在 page1 之后、page2 之前
        let ordered = all.map(\.id)
        XCTAssertEqual(ordered.firstIndex(of: page3.id), ordered.firstIndex(of: page1.id).map { $0 + 1 })
    }

    /// 归一化持续失败时，reorder 抛错且不写入任何新 sortIndex（无半成品状态）。
    func test_pages_reorder_normalizeFails_propagatesAndLeavesStateUntouched() async throws {
        let repository = MockPageRepository()
        let useCase = ReorderPagesUseCase(repository: repository)
        let collectionID = UUID()

        let page1 = makePage(collectionID: collectionID, sortIndex: 1000)
        let page2 = makePage(collectionID: collectionID, sortIndex: 1000.0005)
        let page3 = makePage(collectionID: collectionID, sortIndex: 5000)
        repository.storedPages = [page1, page2, page3]
        repository.shouldThrowOnNormalize = true

        do {
            try await useCase.execute(collectionID: collectionID, moving: page3.id, after: page1.id)
            XCTFail("归一化失败应向上传播")
        } catch {
            XCTAssertNotNil(error)
        }

        // page3 的 sortIndex 未被改写，操作在写入前已中止
        let page3After = try await repository.fetch(by: page3.id)
        XCTAssertEqual(page3After?.sortIndex, 5000)
    }

    // MARK: - Collections（ReorderCollectionsUseCase）

    func test_collections_reorder_triggersGuardRail_noDuplicateSortIndex() async throws {
        let repository = MockCollectionRepository()
        let useCase = ReorderCollectionsUseCase(repository: repository)

        let c1 = makeCollection(sortIndex: 1000)
        let c2 = makeCollection(sortIndex: 1000.0005)
        let c3 = makeCollection(sortIndex: 5000)
        repository.storedCollections = [c1, c2, c3]

        try await useCase.execute(moving: c3.id, after: c1.id)

        XCTAssertEqual(repository.normalizeCallCount, 1, "间隙过小应触发一次同步归一化")

        let all = try await repository.fetchAll().sorted { $0.sortIndex < $1.sortIndex }
        assertStrictlyAscendingUnique(all.map(\.sortIndex))
        let ordered = all.map(\.id)
        XCTAssertEqual(ordered.firstIndex(of: c3.id), ordered.firstIndex(of: c1.id).map { $0 + 1 })
    }

    // MARK: - Node（NodeMutationService.insertAfter）

    /// 连续在同一对相邻节点间反复插入：多次触发同步护栏后，
    /// 全体同级节点 sortIndex 始终唯一、严格有序，不会跌破浮点精度。
    func test_node_repeatedInsertAfter_betweenSamePair_staysStable() async throws {
        let nodeRepository = MockNodeRepository()
        let blockRepository = MockBlockRepository()
        let service = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
        let pageID = UUID()

        let anchor = makeNode(pageID: pageID, sortIndex: 1000)
        let tail = makeNode(pageID: pageID, sortIndex: 2000)
        nodeRepository.storedNodes = [anchor, tail]

        // 每次都在 anchor 之后插入 —— 新节点持续挤进 anchor 与其后继之间，间隙不断减半
        for _ in 0..<60 {
            _ = try await service.insertAfter(nodeID: anchor.id, in: pageID)
        }

        XCTAssertGreaterThanOrEqual(nodeRepository.normalizeCallCount, 1, "反复压缩间隙应至少触发一次同步归一化")

        let sortIndexes = nodeRepository.storedNodes
            .filter { $0.pageID == pageID && $0.parentNodeID == nil }
            .map(\.sortIndex)
            .sorted()
        assertStrictlyAscendingUnique(sortIndexes)
    }

    /// 归一化持续失败时，insertAfter 抛错且不创建任何新节点（无半成品状态）。
    func test_node_insertAfter_normalizeFails_propagatesAndCreatesNothing() async throws {
        let nodeRepository = MockNodeRepository()
        let blockRepository = MockBlockRepository()
        let service = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
        let pageID = UUID()

        let anchor = makeNode(pageID: pageID, sortIndex: 1000)
        let tail = makeNode(pageID: pageID, sortIndex: 1000.0005)
        nodeRepository.storedNodes = [anchor, tail]
        nodeRepository.shouldThrowOnNormalize = true

        do {
            _ = try await service.insertAfter(nodeID: anchor.id, in: pageID)
            XCTFail("归一化失败应向上传播")
        } catch {
            XCTAssertNotNil(error)
        }

        XCTAssertEqual(nodeRepository.storedNodes.count, 2, "护栏在写入前中止，不应创建新节点")
        XCTAssertTrue(blockRepository.storedBlocks.isEmpty, "不应创建配套的空 Block")
    }

    /// outdent 反缩进也应用同步护栏：父节点与其后继间隙过小时先归一化。
    func test_node_outdent_triggersGuardRail_noDuplicateSortIndex() async throws {
        let nodeRepository = MockNodeRepository()
        let blockRepository = MockBlockRepository()
        let service = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
        let pageID = UUID()

        // 顶层 parent1 与 parent2 间隙过小；child 挂在 parent1 下
        let parent1 = makeNode(pageID: pageID, sortIndex: 1000)
        let parent2 = makeNode(pageID: pageID, sortIndex: 1000.0005)
        let child = makeNode(pageID: pageID, parentNodeID: parent1.id, sortIndex: 1000)
        nodeRepository.storedNodes = [parent1, parent2, child]

        try await service.outdent(nodeID: child.id, in: pageID)

        XCTAssertEqual(nodeRepository.normalizeCallCount, 1, "间隙过小应触发一次同步归一化")

        let updatedChild = try await nodeRepository.fetch(by: child.id)
        XCTAssertNil(updatedChild?.parentNodeID, "反缩进后 child 应升到顶层")

        let topLevel = nodeRepository.storedNodes
            .filter { $0.pageID == pageID && $0.parentNodeID == nil }
            .map(\.sortIndex)
            .sorted()
        assertStrictlyAscendingUnique(topLevel)
    }

    // MARK: - Block（BlockEditingService.reorderBlock）

    func test_block_reorder_triggersGuardRail_noDuplicateSortIndex() async throws {
        let blockRepository = MockBlockRepository()
        let service = BlockEditingService(blockRepository: blockRepository)
        let nodeID = UUID()

        let b1 = makeBlock(nodeID: nodeID, sortIndex: 1000)
        let b2 = makeBlock(nodeID: nodeID, sortIndex: 1000.0005)
        let b3 = makeBlock(nodeID: nodeID, sortIndex: 5000)
        blockRepository.storedBlocks = [b1, b2, b3]

        try await service.reorderBlock(blockID: b3.id, after: b1.id)

        XCTAssertEqual(blockRepository.normalizeCallCount, 1, "间隙过小应触发一次同步归一化")

        let all = try await blockRepository.fetchAll(in: nodeID).sorted { $0.sortIndex < $1.sortIndex }
        assertStrictlyAscendingUnique(all.map(\.sortIndex))
        let ordered = all.map(\.id)
        XCTAssertEqual(ordered.firstIndex(of: b3.id), ordered.firstIndex(of: b1.id).map { $0 + 1 })
    }

    /// 归一化持续失败时，reorderBlock 抛错且 Block 的 sortIndex 未被改写。
    func test_block_reorder_normalizeFails_propagatesAndLeavesStateUntouched() async throws {
        let blockRepository = MockBlockRepository()
        let service = BlockEditingService(blockRepository: blockRepository)
        let nodeID = UUID()

        let b1 = makeBlock(nodeID: nodeID, sortIndex: 1000)
        let b2 = makeBlock(nodeID: nodeID, sortIndex: 1000.0005)
        let b3 = makeBlock(nodeID: nodeID, sortIndex: 5000)
        blockRepository.storedBlocks = [b1, b2, b3]
        blockRepository.shouldThrowOnNormalize = true

        do {
            try await service.reorderBlock(blockID: b3.id, after: b1.id)
            XCTFail("归一化失败应向上传播")
        } catch {
            XCTAssertNotNil(error)
        }

        let b3After = try await blockRepository.fetch(by: b3.id)
        XCTAssertEqual(b3After?.sortIndex, 5000)
    }

    // MARK: - Helpers

    private func assertStrictlyAscendingUnique(
        _ values: [Double],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(Set(values).count, values.count, "存在重复 sortIndex", file: file, line: line)
        for (a, b) in zip(values, values.dropFirst()) {
            XCTAssertLessThan(a, b, "sortIndex 未严格递增", file: file, line: line)
        }
    }

    private func makePage(collectionID: UUID, sortIndex: Double) -> Page {
        Page(
            id: UUID(),
            collectionID: collectionID,
            title: "",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isArchived: false
        )
    }

    private func makeCollection(sortIndex: Double) -> Collection {
        Collection(
            id: UUID(),
            title: "",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isPinned: false
        )
    }

    private func makeNode(pageID: UUID, parentNodeID: UUID? = nil, sortIndex: Double) -> Node {
        Node(
            id: UUID(),
            pageID: pageID,
            parentNodeID: parentNodeID,
            title: "",
            sortIndex: sortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeBlock(nodeID: UUID, sortIndex: Double) -> Block {
        Block(
            id: UUID(),
            nodeID: nodeID,
            type: .text,
            content: "",
            sortIndex: sortIndex,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
