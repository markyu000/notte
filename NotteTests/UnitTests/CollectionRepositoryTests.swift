//
//  CollectionRepositoryTests.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/6.
//

import XCTest
import SwiftData
@testable import Notte

@MainActor
final class CollectionRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var repository: CollectionRepository!
    
    override func setUp() async throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
        repository = CollectionRepository(context: context)
    }
    
    func test_fetchAll_whenEmpty_returnsEmptyArray() async throws {
        let result = try await repository.fetchAll()
        XCTAssertTrue(result.isEmpty)
    }

    func test_create_withValidCollection_persistsSuccessfully() async throws {
        let collection = makeCollection(title: "测试")
        try await repository.create(collection)

        let result = try await repository.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "测试")
    }

    func test_fetch_byExistingID_returnsCollection() async throws {
        let collection = makeCollection(title: "查找测试")
        try await repository.create(collection)

        let found = try await repository.fetch(by: collection.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "查找测试")
    }
    
    func test_update_existingCollection_updatesTitle() async throws {
        var collection = makeCollection(title: "旧标题")
        try await repository.create(collection)
        collection.title = "新标题"
        try await repository.update(collection)

        let updated = try await repository.fetch(by: collection.id)
        XCTAssertEqual(updated?.title, "新标题")
    }
    
    func test_delete_existingCollection_removesFromStore() async throws {
        let collection = makeCollection(title: "待删除")
        try await repository.create(collection)
        try await repository.delete(by: collection.id)

        let result = try await repository.fetchAll()
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
    
    //MARK: - Helpers

    private func makeCollection(title: String, sortIndex: Double = 1000) -> Collection {
        Collection(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isPinned: false
        )
    }
}
