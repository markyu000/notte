//
//  DeletePageUseCaseTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import XCTest
@testable import Notte

@MainActor
final class DeletePageUseCaseTests: XCTestCase {

    var pageRepository: MockPageRepository!
    var nodeRepository: MockNodeRepository!
    var useCase: DeletePageUseCase!

    override func setUp() {
        pageRepository = MockPageRepository()
        nodeRepository = MockNodeRepository()
        useCase = DeletePageUseCase(
            repository: pageRepository,
            nodeRepository: nodeRepository
        )
    }

    func test_execute_deletesPageAndCascadesNodes() async throws {
        let collectionID = UUID()
        let page = Page(
            id: UUID(),
            collectionID: collectionID,
            title: "待删除",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isArchived: false
        )
        try await pageRepository.create(page)

        let node = Node(
            id: UUID(),
            pageID: page.id,
            parentNodeID: nil,
            title: "节点",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepository.create(node)

        try await useCase.execute(pageID: page.id)

        let pages = try await pageRepository.fetchAll(in: collectionID)
        let nodes = try await nodeRepository.fetchAll(in: page.id)
        XCTAssertTrue(pages.isEmpty, "Page 应该已被删除")
        XCTAssertTrue(nodes.isEmpty, "关联 Node 应该已被级联删除")
    }
}
