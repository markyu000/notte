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

    func fetchAll(in nodeID: UUID) async throws -> [Block] {
        throw RepositoryError.notImplemented
    }

    func fetch(by id: UUID) async throws -> Block? {
        throw RepositoryError.notImplemented
    }

    func create(_ block: Block) async throws {
        throw RepositoryError.notImplemented
    }

    func update(_ block: Block) async throws {
        throw RepositoryError.notImplemented
    }

    func delete(by id: UUID) async throws {
        throw RepositoryError.notImplemented
    }

    func deleteAll(in nodeID: UUID) async throws {
        throw RepositoryError.notImplemented
    }
}
