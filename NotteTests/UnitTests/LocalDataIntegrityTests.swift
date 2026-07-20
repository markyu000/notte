//
//  LocalDataIntegrityTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/17.
//

import XCTest
import SwiftData
@testable import Notte

/// 验证同步不可用时本地数据完整性：
/// inMemory 容器 = CloudKit 同步路径被完全旁路，只剩本地存储层。
@MainActor
final class LocalDataIntegrityTests: XCTestCase {

    var container: ModelContainer!
    var collectionRepo: CollectionRepository!
    var nodeRepo: NodeRepository!

    override func setUpWithError() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let normalizationActor = SortIndexNormalizationActor(modelContainer: container)
        collectionRepo = CollectionRepository(context: context, normalizationActor: normalizationActor)
        nodeRepo = NodeRepository(context: context)
    }

    /// 测试：CloudKit 不可用时，Collection CRUD 完整可用
    func testCollectionCRUDWithoutCloudKit() async throws {
        let id = UUID()
        let collection = Collection(
            id: id,
            title: "本地 Collection",
            iconName: nil,
            colorToken: nil,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isPinned: false
        )
        try await collectionRepo.create(collection)

        let all = try await collectionRepo.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, id)
        XCTAssertEqual(all.first?.title, "本地 Collection")
    }

    /// 测试：CloudKit 不可用时，Node 写入后本地仍可独立读取
    func testNodeDataPersistsLocallyWithoutCloudKit() async throws {
        let nodeID = UUID()
        let node = Node(
            id: nodeID,
            pageID: UUID(),
            parentNodeID: nil,
            title: "离线节点",
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepo.create(node)

        let fetched = try await nodeRepo.fetch(by: nodeID)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "离线节点")
    }

    /// 测试：连续多次写入，数据量准确，无静默丢失
    func testConsecutiveWritesDontLoseData() async throws {
        let pageID = UUID()
        let ids = (0..<5).map { _ in UUID() }
        for (i, id) in ids.enumerated() {
            let node = Node(
                id: id,
                pageID: pageID,
                parentNodeID: nil,
                title: "节点 \(i)",
                sortIndex: Double(i + 1) * 1000,
                isCollapsed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await nodeRepo.create(node)
        }
        for id in ids {
            let fetched = try await nodeRepo.fetch(by: id)
            XCTAssertNotNil(fetched, "节点 \(id) 写入后应可本地读取")
        }
    }
}
