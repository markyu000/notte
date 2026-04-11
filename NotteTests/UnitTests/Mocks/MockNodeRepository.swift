//
//  MockNodeRepository.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/11.
//

import Foundation
@testable import Notte

@MainActor
class MockNodeRepository: NodeRepositoryProtocol {

    var storedNodes: [Node] = []

    func fetchAll(in pageID: UUID) async throws -> [Node] {
        storedNodes.filter { $0.pageID == pageID }
    }

    func fetch(by id: UUID) async throws -> Node? {
        storedNodes.first { $0.id == id }
    }

    func create(_ node: Node) async throws {
        storedNodes.append(node)
    }

    func update(_ node: Node) async throws {
        guard let index = storedNodes.firstIndex(where: { $0.id == node.id }) else {
            throw RepositoryError.notFound
        }
        storedNodes[index] = node
    }

    func delete(by id: UUID) async throws {
        guard let index = storedNodes.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        storedNodes.remove(at: index)
    }

    func deleteAll(in pageID: UUID) async throws {
        storedNodes.removeAll { $0.pageID == pageID }
    }
}
