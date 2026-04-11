//
//  FetchCollectionsUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

struct FetchCollectionsUseCase {
    let repository: CollectionRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute() async throws -> [Collection] {
        logger.debug("获取所有 Collection", function: #function)
        let all = try await repository.fetchAll()
        logger.info("获取到 \(all.count) 个 Collection", function: #function)
        // 固定的排前面，同组内按 sortIndex 升序
        return all.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.sortIndex < $1.sortIndex
        }
    }
}
