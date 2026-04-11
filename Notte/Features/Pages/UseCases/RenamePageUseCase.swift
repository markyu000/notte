//
//  RenamePageUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct RenamePageUseCase {
    let repository: PageRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(id: UUID, newTitle: String) async throws {
        logger.debug("重命名 Page, id=\(id), newTitle=\(newTitle)", function: #function)
        guard var page = try await repository.fetch(by: id) else {
            logger.error("Page 未找到, id=\(id)", function: #function)
            throw AppError.repositoryError(.notFound)
        }
        page.title = newTitle
        page.updatedAt = Date()
        try await repository.update(page)
        logger.info("Page 重命名成功, id=\(id), newTitle=\(newTitle)", function: #function)
    }
}