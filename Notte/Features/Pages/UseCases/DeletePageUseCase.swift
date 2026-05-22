//
//  DeletePageUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct DeletePageUseCase {
    let repository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(pageID: UUID) async throws {
        logger.debug("开始删除 Page（含级联）, id=\(pageID)", function: #function)
        // 1. 获取所有 Node
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        // 2. 逐 Node 删除其关联 Block
        for node in nodes {
            try await blockRepository.deleteAll(in: node.id)
        }
        // 3. 删除所有 Node
        try await nodeRepository.deleteAll(in: pageID)
        // 4. 删除 Page 本身
        try await repository.delete(by: pageID)
        logger.info("Page 删除成功（含 \(nodes.count) 个 Node）, id=\(pageID)", function: #function)
    }
}
