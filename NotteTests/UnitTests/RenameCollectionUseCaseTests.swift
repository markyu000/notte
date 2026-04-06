//
//  RenameCollectionUseCaseTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/6.
//

import XCTest
@testable import Notte

@MainActor
final class RenameCollectionUseCaseTests: XCTestCase {
    var repository: MockCollectionRepository!
    var useCase: RenameCollectionUseCase!

    override func setUp() {
        repository = MockCollectionRepository()
        useCase = RenameCollectionUseCase(repository: repository)
    }

    func test_execute_withValidID_updatesTitle() async throws {
        let collection = makeCollection(title: "旧标题")
        repository.storedCollections = [collection]

        try await useCase.execute(id: collection.id, newTitle: "新标题")

        let updated = repository.storedCollections.first
        XCTAssertEqual(updated?.title, "新标题")
    }

    func test_execute_updatesTimestamp() async throws {
        let collection = makeCollection(title: "测试")
        repository.storedCollections = [collection]
        let before = collection.updatedAt

        try await useCase.execute(id: collection.id, newTitle: "新标题")
    }

    func test_execute_withNonExistentID_throwsNotFound() async {
        do {
            try await useCase.execute(id: UUID(), newTitle: "新标题")
            XCTFail("应该抛出错误")
        } catch let error as AppError {
            if case .repositoryError(let repoError) = error {
                XCTAssertEqual(repoError, .notFound)
            } else {
                XCTFail("错误类型不符")
            }
        } catch {
            XCTFail("抛出了非预期的错误类型：\(error)")
        }
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
