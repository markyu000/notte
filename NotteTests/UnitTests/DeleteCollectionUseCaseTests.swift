//
//  DeleteCollectionUseCaseTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/6.
//

import XCTest
@testable import Notte

@MainActor
final class DeleteCollectionUseCaseTests: XCTestCase {
    var repository: MockCollectionRepository!
    var pageRepository: MockPageRepository!
    var nodeRepository: MockNodeRepository!
    var useCase: DeleteCollectionUseCase!

    override func setUp() {
        repository = MockCollectionRepository()
        pageRepository = MockPageRepository()
        nodeRepository = MockNodeRepository()
        useCase = DeleteCollectionUseCase(
            repository: repository,
            pageRepository: pageRepository,
            nodeRepository: nodeRepository
        )
    }

    func test_execute_withValidID_removesCollection() async throws {
        let collection = makeCollection(title: "待删除")
        repository.storedCollections = [collection]

        try await useCase.execute(id: collection.id)

        XCTAssertTrue(repository.storedCollections.isEmpty)
    }
    
    func test_execute_withNonExistentID_throwsError() async {
        do {
            try await useCase.execute(id: UUID())
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_execute_onlyDeletesTargetCollection() async throws {
        let target = makeCollection(title: "删除目标")
        let other = makeCollection(title: "保留")
        repository.storedCollections = [target, other]

        try await useCase.execute(id: target.id)

        XCTAssertEqual(repository.storedCollections.count, 1)
        XCTAssertEqual(repository.storedCollections.first?.title, "保留")
    }
    
    // MARK: - Helpers

    private func makeCollection(title: String) -> Collection {
        Collection(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isPinned: false
        )
    }
}