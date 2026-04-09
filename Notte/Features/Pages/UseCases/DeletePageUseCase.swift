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

    func execute(pageID: UUID) async throws {
        // 1. 先级联删除该 Page 下的所有 Node
        try await nodeRepository.deleteAll(in: pageID)
        // 2. 再删除 Page 本身
        try await repository.delete(by: pageID)
    }
}