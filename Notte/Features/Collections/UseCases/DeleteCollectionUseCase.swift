//
//  DeleteCollectionUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

import Foundation

struct DeleteCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(id: UUID) async throws {
        try await repository.delete(by: id)
    }
}
