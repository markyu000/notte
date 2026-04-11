//
//  RenameCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct RenameCollectionUseCase {
    let repository: CollectionRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(id: UUID, newTitle: String) async throws {
        logger.debug("重命名 Collection, id=\(id), newTitle=\(newTitle)", function: #function)
        guard var collection = try await repository.fetch(by: id) else {
            logger.error("Collection 未找到, id=\(id)", function: #function)
            throw AppError.repositoryError(.notFound)
        }
        collection.title = newTitle
        collection.updatedAt = Date()
        try await repository.update(collection)
        logger.info("Collection 重命名成功, id=\(id), newTitle=\(newTitle)", function: #function)
    }
}
