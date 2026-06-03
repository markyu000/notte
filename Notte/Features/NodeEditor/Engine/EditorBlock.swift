//
//  EditorBlock.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/12.
//

import Foundation

/// Block 的运行时模型，随所属 EditorNode 一起携带。
/// MVP 阶段 type 只有 .text，但结构已为 POST 类型预留。
struct EditorBlock: Identifiable, Equatable {
    let id: UUID
    var type: BlockType
    var content: String
    var sortIndex: Double
    /// 图片私有渲染属性（仅 image 类型有意义），不写入 .md
    var imageWidthRatio: ImageWidthRatio?
    var imageAlignment: BlockAlignment?

    init(
        id: UUID,
        type: BlockType = .text,
        content: String = "",
        sortIndex: Double,
        imageWidthRatio: ImageWidthRatio? = nil,
        imageAlignment: BlockAlignment? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.sortIndex = sortIndex
        self.imageWidthRatio = imageWidthRatio
        self.imageAlignment = imageAlignment
    }
}
