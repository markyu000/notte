//
//  BlockModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

@Model
class BlockModel {
    @Attribute(.unique) var id: UUID = UUID()
    var nodeID: UUID = UUID()
    var type: String = BlockType.text.rawValue
    var content: String = ""
    var sortIndex: Double = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        nodeID: UUID,
        type: String = BlockType.text.rawValue,
        content: String = "",
        sortIndex: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.nodeID = nodeID
        self.type = type
        self.content = content
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension BlockModel {
    func toDomain() -> Block {
        Block(
            id: id,
            nodeID: nodeID,
            type: BlockType(rawValue: type) ?? .text,
            content: content,
            sortIndex: sortIndex,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
