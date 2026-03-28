//
//  FetchCollectionsUseCase.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/29.
//

struct FetchCollectionsUseCase {
    let repository: CollectionRepositoryProtocol

    func execute() async throws -> [Collection] {
        let all = try await repository.fetchAll()
        // 固定的排前面，同组内按 sortIndex 升序
        return all.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.sortIndex < $1.sortIndex
        }
    }
}
