//
//  BlockRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class BlockRepository: BlockRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in nodeID: UUID) throws -> [Block] {
        throw RepositoryError.notImplemented
    }

    func fetch(by id: UUID) throws -> Block? {
        throw RepositoryError.notImplemented
    }

    func create(_ block: Block) throws {
        throw RepositoryError.notImplemented
    }

    func update(_ block: Block) throws {
        throw RepositoryError.notImplemented
    }

    func delete(by id: UUID) throws {
        throw RepositoryError.notImplemented
    }

    func deleteAll(in nodeID: UUID) throws {
        throw RepositoryError.notImplemented
    }
}
