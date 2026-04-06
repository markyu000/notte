//
//  PinCollectionUseCaseTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/6.
//

import XCTest
@testable import Notte

@MainActor
final class PinCollectionUseCaseTests: XCTestCase {
    var repository: MockCollectionRepository!
    var useCase: PinCollectionUseCase!

    override func setUp() {
        repository = MockCollectionRepository()
        useCase = PinCollectionUseCase(repository: repository)
    }

    func test_execute_unpinnedCollection_becomesPin() async throws {
        let collection = makeCollection(isPinned: false)
        repository.storedCollections = [collection]

        try await useCase.execute(id: collection.id)

        XCTAssertTrue(repository.storedCollections.first!.isPinned)
    }
    
    func test_execute_pinnedCollection_becomesUnpinned() async throws {
        let collection = makeCollection(isPinned: true)
        repository.storedCollections = [collection]

        try await useCase.execute(id: collection.id)

        XCTAssertFalse(repository.storedCollections.first!.isPinned)
    }
    
    func test_execute_withNonExistentID_throwsNotFound() async {
        do {
            try await useCase.execute(id: UUID())
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

    private func makeCollection(isPinned: Bool) -> Collection {
        Collection(
            id: UUID(),
            title: "测试",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isPinned: isPinned
        )
    }
}
