import Foundation
@testable import Notte

@MainActor
class MockBlockRepository: BlockRepositoryProtocol {

    var storedBlocks: [Block] = []
    var shouldThrowOnNormalize = false
    var normalizeCallCount = 0

    func fetchAll(in nodeID: UUID) async throws -> [Block] {
        storedBlocks.filter { $0.nodeID == nodeID }
    }

    func fetch(by id: UUID) async throws -> Block? {
        storedBlocks.first { $0.id == id }
    }

    func create(_ block: Block) async throws {
        storedBlocks.append(block)
    }

    func update(_ block: Block) async throws {
        guard let index = storedBlocks.firstIndex(where: { $0.id == block.id }) else {
            throw RepositoryError.notFound
        }
        storedBlocks[index] = block
    }

    func delete(by id: UUID) async throws {
        guard let index = storedBlocks.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        storedBlocks.remove(at: index)
    }

    func deleteAll(in nodeID: UUID) async throws {
        storedBlocks.removeAll { $0.nodeID == nodeID }
    }

    /// 忠实复现真实归一化：按 nodeID 过滤后跑域层 SortIndexNormalizer 并写回。
    func normalizeSortIndexesIfNeeded(in nodeID: UUID) async throws {
        normalizeCallCount += 1
        if shouldThrowOnNormalize {
            throw RepositoryError.saveFailed(NSError(domain: "MockBlockRepository", code: -2))
        }
        let scoped = storedBlocks.filter { $0.nodeID == nodeID }
        try await SortIndexNormalizer.normalizeIfNeeded(scoped) { updated in
            if let index = storedBlocks.firstIndex(where: { $0.id == updated.id }) {
                storedBlocks[index] = updated
            }
        }
    }
}
