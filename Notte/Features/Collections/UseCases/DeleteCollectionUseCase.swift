//
//  DeleteCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct DeleteCollectionUseCase {
    let repository: CollectionRepositoryProtocol
    let pageRepository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(id: UUID) async throws {
        logger.debug("开始删除 Collection, id=\(id)", function: #function)
        // 1. 获取该 Collection 下所有 Page
        let pages = try await pageRepository.fetchAll(in: id)
        logger.debug("Collection 下有 \(pages.count) 个 Page 需要删除", function: #function)
        // 2. 逐 Page 删除其关联 Node
        for page in pages {
            try? await nodeRepository.deleteAll(in: page.id)
        }
        // 3. 删除所有 Page
        for page in pages {
            try await pageRepository.delete(by: page.id)
            logger.debug("已删除 Page, id=\(page.id)", function: #function)
        }
        // 4. 删除 Collection 本身
        try await repository.delete(by: id)
        logger.info("Collection 删除成功, id=\(id), 共删除 \(pages.count) 个 Page", function: #function)
    }
}
