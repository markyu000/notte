import Foundation
@testable import Notte

@MainActor
class MockBlockRepository: BlockRepositoryProtocol {

    var storedBlocks: [Block] = []

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
}
