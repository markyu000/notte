//
//  PageRepositoryTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import XCTest
import SwiftData
@testable import Notte

@MainActor
final class PageRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var repository: PageRepository!
    let collectionID = UUID()

    override func setUp() async throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
        repository = PageRepository(context: context)
    }

    func test_fetchAll_whenEmpty_returnsEmptyArray() async throws {
        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertTrue(result.isEmpty)
    }

    func test_fetchAll_onlyReturnsMatchingCollectionID() async throws {
        let otherCollectionID = UUID()
        try await repository.create(makePage(title: "属于本集合", collectionID: collectionID))
        try await repository.create(makePage(title: "属于其他集合", collectionID: otherCollectionID))

        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "属于本集合")
    }

    func test_create_withValidPage_persistsSuccessfully() async throws {
        let page = makePage(title: "测试页面")
        try await repository.create(page)

        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "测试页面")
    }

    func test_update_existingPage_updatesTitle() async throws {
        var page = makePage(title: "旧标题")
        try await repository.create(page)
        page.title = "新标题"
        try await repository.update(page)

        let updated = try await repository.fetch(by: page.id)
        XCTAssertEqual(updated?.title, "新标题")
    }

    func test_delete_existingPage_removesFromStore() async throws {
        let page = makePage(title: "待删除")
        try await repository.create(page)
        try await repository.delete(by: page.id)

        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertTrue(result.isEmpty)
    }

    func test_delete_nonExistentID_throwsNotFound() async throws {
        do {
            try await repository.delete(by: UUID())
            XCTFail("应该抛出错误")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - Helpers

    private func makePage(title: String, collectionID: UUID? = nil, sortIndex: Double = 1000) -> Page {
        Page(
            id: UUID(),
            collectionID: collectionID ?? self.collectionID,
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isArchived: false
        )
    }
}
