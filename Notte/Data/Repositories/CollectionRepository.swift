//
//  CollectionRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class CollectionRepository: CollectionRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Collection] {
        throw RepositoryError.notImplemented
    }

    func fetch(by id: UUID) throws -> Collection? {
        throw RepositoryError.notImplemented
    }

    func create(_ collection: Collection) throws {
        throw RepositoryError.notImplemented
    }

    func update(_ collection: Collection) throws {
        throw RepositoryError.notImplemented
    }

    func delete(by id: UUID) throws {
        throw RepositoryError.notImplemented
    }
}
