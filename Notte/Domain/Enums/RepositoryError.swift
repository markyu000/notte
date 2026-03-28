//
//  RepositoryError.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/27.
//

import Foundation

enum RepositoryError: Error {
    case notImplemented
    case notFound
    case saveFailed(Error)
}
