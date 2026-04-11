//
//  PinCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct PinCollectionUseCase {
    let repository: CollectionRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(id: UUID) async throws {
        logger.debug("切换 Collection 置顶状态, id=\(id)", function: #function)
        guard var entity = try await repository.fetch(by: id) else {
            logger.error("Collection 未找到, id=\(id)", function: #function)
            throw AppError.repositoryError(.notFound)
        }
        entity.isPinned.toggle()
        entity.updatedAt = Date()
        try await repository.update(entity)
        logger.info("Collection 置顶状态已切换, id=\(id), isPinned=\(entity.isPinned)", function: #function)
    }
}
