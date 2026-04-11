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

    func execute(id: UUID) async throws {
        // 1. 获取该 Collection 下所有 Page
        let pages = try await pageRepository.fetchAll(in: id)
        // 2. 逐 Page 删除其关联 Node
        for page in pages {
            try? await nodeRepository.deleteAll(in: page.id)
        }
        // 3. 删除所有 Page
        for page in pages {
            try await pageRepository.delete(by: page.id)
        }
        // 4. 删除 Collection 本身
        try await repository.delete(by: id)
    }
}
