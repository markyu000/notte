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
    var updateCallCount = 0
    var shouldThrowOnNormalize = false
    var normalizeCallCount = 0

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
        updateCallCount += 1
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

    /// 忠实复现真实归一化：按 pageID + parentNodeID 过滤同级节点后跑域层 SortIndexNormalizer 并写回。
    func normalizeSortIndexesIfNeeded(in pageID: UUID, parentNodeID: UUID?) async throws {
        normalizeCallCount += 1
        if shouldThrowOnNormalize {
            throw RepositoryError.saveFailed(NSError(domain: "MockNodeRepository", code: -2))
        }
        let scoped = storedNodes.filter { $0.pageID == pageID && $0.parentNodeID == parentNodeID }
        try await SortIndexNormalizer.normalizeIfNeeded(scoped) { updated in
            if let index = storedNodes.firstIndex(where: { $0.id == updated.id }) {
                storedNodes[index] = updated
            }
        }
    }
}
