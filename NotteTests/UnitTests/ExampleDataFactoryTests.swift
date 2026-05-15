//
//  ExampleDataFactoryTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/15.
//

import XCTest
@testable import Notte

@MainActor
final class ExampleDataFactoryTests: XCTestCase {

    var collectionRepository: MockCollectionRepository!
    var pageRepository: MockPageRepository!
    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var factory: ExampleDataFactory!

    override func setUp() {
        super.setUp()
        collectionRepository = MockCollectionRepository()
        pageRepository = MockPageRepository()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        factory = ExampleDataFactory(
            collectionRepository: collectionRepository,
            pageRepository: pageRepository,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
    }

    /// 测试：导入 SwiftUILearning 后 Collection 数量 +1，Page 与 Node 数量符合 JSON
    func testImportSwiftUILearning() async throws {
        try await factory.importOne(file: "SwiftUILearning")

        XCTAssertEqual(collectionRepository.storedCollections.count, 1)
        XCTAssertEqual(collectionRepository.storedCollections.first?.title, "SwiftUI 学习")
        XCTAssertEqual(pageRepository.storedPages.count, 3)
        XCTAssertGreaterThanOrEqual(nodeRepository.storedNodes.count, 12)
    }

    /// 测试：导入全部示例后三个 Collection 均存在且 sortIndex 互不冲突
    func testImportAllProducesDistinctSortIndexes() async throws {
        try await factory.importAll()
        let sortIndexes = collectionRepository.storedCollections.map(\.sortIndex)
        XCTAssertEqual(Set(sortIndexes).count, sortIndexes.count, "sortIndex 必须唯一")
        XCTAssertEqual(collectionRepository.storedCollections.count, 3)
    }

    /// 测试：嵌套 Node 的 parentNodeID 指向同一 Page 内的父 Node
    func testNestedNodesLinkToParent() async throws {
        try await factory.importOne(file: "SwiftUILearning")
        let nodes = nodeRepository.storedNodes
        let childNodes = nodes.filter { $0.depth > 0 }
        XCTAssertFalse(childNodes.isEmpty)
        for child in childNodes {
            XCTAssertNotNil(child.parentNodeID)
            XCTAssertTrue(nodes.contains(where: { $0.id == child.parentNodeID }))
        }
    }
}
