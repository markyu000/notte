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

    var errorDescription: String? {
        switch self {
        case .repositoryError(let e):
            return "数据操作失败：\(e)"
        case.validationFailure(let message):
            return message
        case .unknown(let e):
            return "未知错误：\(e.localizedDescription)"
        }
    }
}
