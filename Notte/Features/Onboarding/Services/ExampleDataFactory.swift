//
//  ExampleDataFactory.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/13.
//

import Foundation

/// JSON Schema：
/// {
///   "title": "Collection 标题",
///   "iconName": "tray.full",
///   "colorToken": null,
///   "pages": [
///     {
///       "title": "Page 标题",
///       "nodes": [
///         {
///           "title": "Node 标题",
///           "depth": 0,
///           "children": [ /* 递归 Node */ ],
///           "blocks": [
///             { "type": "text", "content": "Block 内容" }
///           ]
///         }
///       ]
///     }
///   ]
/// }
struct ExampleDataFactory {
    let collectionRepository: CollectionRepositoryProtocol
    let pageRepository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol

    private let sampleFiles = ["SwiftUILearning", "ProjectPlanning", "ReadingNotes"]
    private let logger = ConsoleLogger()

    func importAll() async throws {
        for file in sampleFiles {
            try await importOne(file: file)
        }
    }

    func importOne(file: String) async throws {
        guard let url = Bundle.main.url(forResource: file, withExtension: "json", subdirectory: "SampleData")
            ?? Bundle.main.url(forResource: file, withExtension: "json") else {
            throw RepositoryError.notFound
        }
        let data = try Data(contentsOf: url)
        let dto = try JSONDecoder().decode(SampleCollectionDTO.self, from: data)
        try await persist(dto: dto)
        logger.info("示例数据导入完成: \(file)", function: #function)
    }

    private func persist(dto: SampleCollectionDTO) async throws {
        let existing = try await collectionRepository.fetchAll()
        let baseSortIndex = (existing.map(\.sortIndex).max() ?? 0) + 1000

        let collection = Collection(
            id: UUID(),
            title: dto.title,
            iconName: dto.iconName,
            colorToken: dto.colorToken,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: baseSortIndex,
            isPinned: false
        )
        try await collectionRepository.create(collection)

        for (pageIdx, pageDTO) in dto.pages.enumerated() {
            let page = Page(
                id: UUID(),
                collectionID: collection.id,
                title: pageDTO.title,
                createdAt: Date(),
                updatedAt: Date(),
                sortIndex: Double(pageIdx + 1) * 1000,
                isArchived: false
            )
            try await pageRepository.create(page)

            try await persistNodes(pageDTO.nodes, pageID: page.id, parentNodeID: nil)
        }
    }

    private func persistNodes(
        _ dtos: [SampleNodeDTO],
        pageID: UUID,
        parentNodeID: UUID?
    ) async throws {
        for (idx, dto) in dtos.enumerated() {
            let node = Node(
                id: UUID(),
                pageID: pageID,
                parentNodeID: parentNodeID,
                title: dto.title,
                depth: dto.depth,
                sortIndex: Double(idx + 1) * 1000,
                isCollapsed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await nodeRepository.create(node)

            let blockDTOs = dto.blocks ?? []
            if blockDTOs.isEmpty {
                let emptyBlock = Block(
                    id: UUID(),
                    nodeID: node.id,
                    type: .text,
                    content: "",
                    sortIndex: 1000,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try await blockRepository.create(emptyBlock)
            } else {
                for (blockIdx, blockDTO) in blockDTOs.enumerated() {
                    let block = Block(
                        id: UUID(),
                        nodeID: node.id,
                        type: BlockType(rawValue: blockDTO.type) ?? .text,
                        content: blockDTO.content,
                        sortIndex: Double(blockIdx + 1) * 1000,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try await blockRepository.create(block)
                }
            }

            try await persistNodes(dto.children ?? [], pageID: pageID, parentNodeID: node.id)
        }
    }
}

// MARK: - DTO

private struct SampleCollectionDTO: Decodable {
    let title: String
    let iconName: String?
    let colorToken: String?
    let pages: [SamplePageDTO]
}

private struct SamplePageDTO: Decodable {
    let title: String
    let nodes: [SampleNodeDTO]
}

private struct SampleNodeDTO: Decodable {
    let title: String
    let depth: Int
    let children: [SampleNodeDTO]?
    let blocks: [SampleBlockDTO]?
}

private struct SampleBlockDTO: Decodable {
    let type: String
    let content: String
}
