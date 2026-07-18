//
//  AppErrorPresenter.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/28.
//

import Foundation

enum AppError: LocalizedError {
    case repositoryError(RepositoryError)
    case validationFailure(String)
    case unknown(Error)
    case syncFailed(Error)
    case nodeError(NodeError)
    
    var errorDescription: String? {
        switch self {
        case .repositoryError(let e):
            return "数据操作失败：\(e)"
        case .validationFailure(let message):
            return message
        case .unknown(let e):
            return "未知错误：\(e.localizedDescription)"
        case .syncFailed(let e):
            return "同步失败： \(e)"
        case .nodeError(let e):
            return "违反Node规则: \(e)"
        }
    }
}

// MARK: - 统一错误映射入口

extension AppError {
    /// 将任意 `Error` 统一映射为 `AppError`，避免 `as? AppError` 把
    /// 非 AppError 错误（如裸 `NodeError`、`RepositoryError`）静默转成 nil。
    ///
    /// 映射规则：
    /// - `AppError` 原样返回
    /// - `NodeError` 包成 `.nodeError`
    /// - `RepositoryError` 包成 `.repositoryError`
    /// - 其余落 `.unknown(error)`
    static func wrap(_ error: Error) -> AppError {
        switch error {
        case let appError as AppError:
            return appError
        case let nodeError as NodeError:
            return .nodeError(nodeError)
        case let repoError as RepositoryError:
            return .repositoryError(repoError)
        default:
            return .unknown(error)
        }
    }
}
