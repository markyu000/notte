//
//  FetchPagesByCollectionUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct FetchPagesByCollectionUseCase {
    let repository: PageRepositoryProtocol
    
    func execute(collectionID: UUID) async throws -> [Page] {
        let all = try await repository.fetchAll(in: collectionID)
        return all.sorted { $0.sortIndex < $1.sortIndex }
    }
}
