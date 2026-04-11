//
//  FetchPagesByCollectionUseCase.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Foundation

struct FetchPagesByCollectionUseCase {
    let repository: PageRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(collectionID: UUID) async throws -> [Page] {
        logger.debug("获取 Collection 下所有 Page, collectionID=\(collectionID)", function: #function)
        let all = try await repository.fetchAll(in: collectionID)
        logger.info("获取到 \(all.count) 个 Page, collectionID=\(collectionID)", function: #function)
        return all.sorted { $0.sortIndex < $1.sortIndex }
    }
}
