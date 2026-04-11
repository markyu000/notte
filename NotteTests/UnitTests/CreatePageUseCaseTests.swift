//
//  CreatePageUseCaseTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import XCTest
@testable import Notte

@MainActor
final class CreatePageUseCaseTests: XCTestCase {

    var repository: MockPageRepository!
    var useCase: CreatePageUseCase!
    let collectionID = UUID()

    override func setUp() {
        repository = MockPageRepository()
        useCase = CreatePageUseCase(repository: repository)
    }

    func test_execute_withValidTitle_returnsPage() async throws {
        let result = try await useCase.execute(title: "新页面", in: collectionID)
        XCTAssertEqual(result.title, "新页面")
        XCTAssertEqual(result.collectionID, collectionID)
    }

    func test_execute_assignsIncrementingSortIndex() async throws {
        let first = try await useCase.execute(title: "第一页", in: collectionID)
        let second = try await useCase.execute(title: "第二页", in: collectionID)
        XCTAssertGreaterThan(second.sortIndex, first.sortIndex)
    }

    func test_execute_whenRepositoryThrows_propagatesError() async {
        repository.shouldThrowOnCreate = true
        do {
            _ = try await useCase.execute(title: "失败测试", in: collectionID)
            XCTFail("应该抛出错误")
        } catch is RepositoryError {
            // 正确抛出了 RepositoryError
        } catch {
            XCTFail("抛出了非预期的错误类型：\(error)")
        }
    }
}
