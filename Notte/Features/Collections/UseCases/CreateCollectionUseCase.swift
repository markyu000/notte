//
//  CreateCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct CreateCollectionUseCase {
    let repository: CollectionRepositoryProtocol
    private let logger = ConsoleLogger()

    @discardableResult
    func execute(title: String) async throws -> Collection {
        logger.debug("开始创建 Collection, title=\(title)", function: #function)
        let all = try await repository.fetchAll()
        let maxIndex = all.map(\.sortIndex).max() ?? 0
        let entity = Collection(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: maxIndex + 1000,
            isPinned: false,
        )
        try await repository.create(entity)
        logger.info("Collection 创建成功, id=\(entity.id), title=\(title)", function: #function)
        return entity
    }
}
