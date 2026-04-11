//
//  ReorderPagesUseCaseTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import XCTest
@testable import Notte

@MainActor
final class ReorderPagesUseCaseTests: XCTestCase {

    var repository: MockPageRepository!
    var useCase: ReorderPagesUseCase!
    let collectionID = UUID()

    override func setUp() {
        repository = MockPageRepository()
        useCase = ReorderPagesUseCase(repository: repository)
    }

    func test_execute_movingToFront_assignsSmallerSortIndex() async throws {
        let page1 = makePage(title: "第一页", sortIndex: 1000)
        let page2 = makePage(title: "第二页", sortIndex: 2000)
        try await repository.create(page1)
        try await repository.create(page2)

        try await useCase.execute(collectionID: collectionID, moving: page2.id, after: nil)

        let result = try await repository.fetchAll(in: collectionID)
        let movedPage = result.first { $0.id == page2.id }!
        let firstPage = result.first { $0.id == page1.id }!
        XCTAssertLessThan(movedPage.sortIndex, firstPage.sortIndex)
    }

    func test_execute_movingAfterTarget_assignsIndexBetween() async throws {
        let page1 = makePage(title: "第一页", sortIndex: 1000)
        let page2 = makePage(title: "第二页", sortIndex: 2000)
        let page3 = makePage(title: "第三页", sortIndex: 3000)
        try await repository.create(page1)
        try await repository.create(page2)
        try await repository.create(page3)

        try await useCase.execute(collectionID: collectionID, moving: page3.id, after: page1.id)

        let moved = try await repository.fetch(by: page3.id)!
        XCTAssertGreaterThan(moved.sortIndex, page1.sortIndex)
        XCTAssertLessThan(moved.sortIndex, page2.sortIndex)
    }

    // MARK: - Helpers

    private func makePage(title: String, sortIndex: Double) -> Page {
        Page(
            id: UUID(),
            collectionID: collectionID,
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isArchived: false
        )
    }
}
