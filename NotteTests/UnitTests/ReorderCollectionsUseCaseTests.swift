//
//  ReorderCollectionsUseCaseTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/6.
//

import XCTest
@testable import Notte

@MainActor 
final class ReorderCollectionsUseCaseTests: XCTestCase {
    var repository: MockCollectionRepository!
    var useCase: ReorderCollectionsUseCase!

    override func setUp() {
        repository = MockCollectionRepository()
        useCase = ReorderCollectionsUseCase(repository: repository)
    }

    func test_execute_moveToFront_assignsSmallerIndex() async throws {
        let a = makeCollection(title: "A", sortIndex: 1000)
        let b = makeCollection(title: "B", sortIndex: 2000)
        let c = makeCollection(title: "C", sortIndex: 3000)
        repository.storedCollections = [a, b, c]

        // 把 C 移到最前面（targetID = nil）
        try await useCase.execute(moving: c.id, after: nil)

        let updated = repository.storedCollections.first { $0.id == c.id }!
        XCTAssertLessThan(updated.sortIndex, a.sortIndex)
    }

    func test_execute_moveBetweenTwo_assignsMiddleIndex() async throws {
        let a = makeCollection(title: "A", sortIndex: 1000)
        let b = makeCollection(title: "B", sortIndex: 2000)
        let c = makeCollection(title: "C", sortIndex: 3000)
        repository.storedCollections = [a, b, c]

        // 把 C 移到 A 之后
        try await useCase.execute(moving: c.id, after: a.id)

        let updated = repository.storedCollections.first { $0.id == c.id }!
        XCTAssertGreaterThan(updated.sortIndex, a.sortIndex)
        XCTAssertLessThan(updated.sortIndex, b.sortIndex)
    }

    func test_execute_withNonExistentID_throwsNotFound() async {
        let a = makeCollection(title: "A", sortIndex: 1000)
        repository.storedCollections = [a]

        do {
            try await useCase.execute(moving: UUID(), after: nil)
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