//
//  NodeRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class NodeRepository: NodeRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in pageID: UUID) throws -> [Node] {
        throw RepositoryError.notImplemented
    }

    func fetch(by id: UUID) throws -> Node? {
        throw RepositoryError.notImplemented
    }

    func create(_ node: Node) throws {
        throw RepositoryError.notImplemented
    }

    func update(_ node: Node) throws {
        throw RepositoryError.notImplemented
    }

    func delete(by id: UUID) throws {
        throw RepositoryError.notImplemented
    }

    func deleteAll(in pageID: UUID) throws {
        throw RepositoryError.notImplemented
    }
}
