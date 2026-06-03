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
    /// 图片私有渲染属性（仅 image 类型有意义），不写入 .md。可空，非 image 块为 nil。
    var imageWidthRatio: String? = nil
    var imageAlignment: String? = nil

    init(
        id: UUID = UUID(),
        nodeID: UUID,
        type: String = BlockType.text.rawValue,
        content: String = "",
        sortIndex: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        imageWidthRatio: String? = nil,
        imageAlignment: String? = nil
    ) {
        self.id = id
        self.nodeID = nodeID
        self.type = type
        self.content = content
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageWidthRatio = imageWidthRatio
        self.imageAlignment = imageAlignment
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
            updatedAt: updatedAt,
            imageWidthRatio: imageWidthRatio.flatMap(ImageWidthRatio.init(rawValue:)),
            imageAlignment: imageAlignment.flatMap(BlockAlignment.init(rawValue:))
        )
    }
}
