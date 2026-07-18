//
//  AppErrorWrapTests.swift
//  Notte
//
//  覆盖 AppError.wrap(_:) 的四条映射分支：
//  AppError 原样返回 / NodeError → .nodeError / RepositoryError → .repositoryError / 其余 → .unknown
//

import XCTest
@testable import Notte

@MainActor
final class AppErrorWrapTests: XCTestCase {

    // MARK: - AppError 原样返回

    /// AppError 传入应原样返回（保持同一 case 与关联值）
    func test_wrap_whenAppError_returnsAsIs() {
        let original = AppError.validationFailure("校验失败")

        let wrapped = AppError.wrap(original)

        if case .validationFailure(let message) = wrapped {
            XCTAssertEqual(message, "校验失败")
        } else {
            XCTFail("应当原样返回 .validationFailure，实际：\(wrapped)")
        }
    }

    // MARK: - NodeError → .nodeError

    /// 裸 NodeError.maxDepthExceeded 应被包成 .nodeError，而非被吞成 nil/unknown
    func test_wrap_whenNodeError_wrapsAsNodeError() {
        let wrapped = AppError.wrap(NodeError.maxDepthExceeded)

        if case .nodeError(let nodeError) = wrapped {
            XCTAssertEqual(nodeError, .maxDepthExceeded)
        } else {
            XCTFail("裸 NodeError 应被包成 .nodeError，实际：\(wrapped)")
        }
    }

    // MARK: - RepositoryError → .repositoryError

    /// 裸 RepositoryError 应被包成 .repositoryError
    func test_wrap_whenRepositoryError_wrapsAsRepositoryError() {
        let wrapped = AppError.wrap(RepositoryError.notFound)

        if case .repositoryError(let repoError) = wrapped {
            XCTAssertEqual(repoError, .notFound)
        } else {
            XCTFail("裸 RepositoryError 应被包成 .repositoryError，实际：\(wrapped)")
        }
    }

    // MARK: - 其余 → .unknown

    /// 非 AppError/NodeError/RepositoryError 的错误应落 .unknown，绝不可转成 nil
    func test_wrap_whenUnknownError_wrapsAsUnknown() {
        struct CustomError: Error {}
        let wrapped = AppError.wrap(CustomError())

        if case .unknown = wrapped {
            // 期望命中
        } else {
            XCTFail("未知错误类型应落 .unknown，实际：\(wrapped)")
        }
    }

    /// NSError（常见于系统/框架抛错）同样应落 .unknown
    func test_wrap_whenNSError_wrapsAsUnknown() {
        let nsError = NSError(domain: "test", code: 42)
        let wrapped = AppError.wrap(nsError)

        if case .unknown(let inner) = wrapped {
            XCTAssertEqual((inner as NSError).code, 42)
        } else {
            XCTFail("NSError 应落 .unknown，实际：\(wrapped)")
        }
    }

    // MARK: - ViewModel 集成：注入非 AppError/NodeError 错误不再被吞成 nil

    /// 通过 MockCollectionRepository.shouldThrowOnCreate 注入 RepositoryError.saveFailed，
    /// 验证 ViewModel.error 非 nil 且映射为 .repositoryError（而非旧的 as? AppError 转成 nil）。
    func test_createCollection_whenRepositoryThrows_surfacesError() async {
        let repository = MockCollectionRepository()
        repository.shouldThrowOnCreate = true
        let viewModel = CollectionListViewModel(
            repository: repository,
            pageRepository: MockPageRepository(),
            nodeRepository: MockNodeRepository()
        )
        viewModel.newCollectionTitle = "新建"

        await viewModel.createCollection()

        XCTAssertNotNil(viewModel.error, "错误不应被静默吞掉")
        if case .repositoryError = viewModel.error {
            // 期望命中
        } else {
            XCTFail("应映射为 .repositoryError，实际：\(String(describing: viewModel.error))")
        }
    }
}
