//
//  RenamePageUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct RenamePageUseCase {
    let repository: PageRepositoryProtocol

    func execute(id: UUID, newTitle: String) async throws {
        guard var page = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        page.title = newTitle
        page.updatedAt = Date()
        try await repository.update(page)
    }
}