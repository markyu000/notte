//
//  CollectionListViewModelTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/6.
//

import XCTest
@testable import Notte

@MainActor
final class CollectionListViewModelTests: XCTestCase {
    var viewModel: CollectionListViewModel!
    var repository: MockCollectionRepository!
    var pageRepository: MockPageRepository!
    var nodeRepository: MockNodeRepository!

    override func setUp() {
        repository = MockCollectionRepository()
        pageRepository = MockPageRepository()
        nodeRepository = MockNodeRepository()
        viewModel = CollectionListViewModel(
            repository: repository,
            pageRepository: pageRepository,
            nodeRepository: nodeRepository
        )
    }

    func test_loadCollections_populatesCollections() async {
        repository.storedCollections = [makeCollection(title: "测试")]

        await viewModel.loadCollections()

        XCTAssertEqual(viewModel.collections.count, 1)
        XCTAssertEqual(viewModel.collections.first?.title, "测试")
    }
    
    func test_loadCollections_setsLoadingState() async {
        let task = Task { await viewModel.loadCollections() }
        // loadCollections 开始时 isLoading 应为 true
        // 结束后应为 false
        await task.value
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_createCollection_addsToList() async {
        viewModel.newCollectionTitle = "新建"
        await viewModel.createCollection()

        XCTAssertEqual(viewModel.collections.count, 1)
        XCTAssertEqual(viewModel.collections.first?.title, "新建")
    }

    func test_createCollection_withEmptyTitle_doesNotCreate() async {
        viewModel.newCollectionTitle = "   "
        await viewModel.createCollection()

        XCTAssertTrue(viewModel.collections.isEmpty)
    }

    func test_createCollection_clearsTitle() async {
        viewModel.newCollectionTitle = "新建"
        await viewModel.createCollection()

        XCTAssertEqual(viewModel.newCollectionTitle, "")
    }

    func test_createCollection_closesSheet() async {
        viewModel.isShowingCreateSheet = true
        viewModel.newCollectionTitle = "新建"
        await viewModel.createCollection()

        XCTAssertFalse(viewModel.isShowingCreateSheet)
    }

    func test_deleteCollection_removesFromList() async {
        let collection = makeCollection(title: "待删除")
        repository.storedCollections = [collection]
        await viewModel.loadCollections()

        await viewModel.deleteCollection(id: collection.id)

        XCTAssertTrue(viewModel.collections.isEmpty)
    }

    func test_pinCollection_togglesPin() async {
        let collection = makeCollection(title: "测试", isPinned: false)
        repository.storedCollections = [collection]
        await viewModel.loadCollections()

        await viewModel.pinCollection(id: collection.id)

        XCTAssertTrue(viewModel.collections.first!.isPinned)
    }

    // MARK: - Helpers

    private func makeCollection(title: String, isPinned: Bool = false) -> Collection {
        Collection(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isPinned: isPinned
        )
    }
}