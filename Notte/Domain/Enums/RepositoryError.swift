//
//  RepositoryError.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/27.
//

import Foundation

enum RepositoryError: Error, Equatable {
    case notImplemented
    case notFound
    case saveFailed(Error)
    
    static func == (lhs: RepositoryError, rhs: RepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.notImplemented, .notImplemented): return true
        case (.notFound, .notFound): return true
        case (.saveFailed, .saveFailed): return true
        default: return false
        }
    }
}
