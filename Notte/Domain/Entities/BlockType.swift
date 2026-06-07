//
//  BlockType.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/25.
//

import Foundation

/// Block 的内容类型，是模板内容的承载层。
/// 本期只有 `.text`，但代码块 / 公式块 / 图片块等未来一律做成 BlockType，
/// 不做成 NodeType——Node 只负责结构作用域（标题 + depth + 折叠），不承载内容类型。
enum BlockType: String, Codable, Hashable {
    case text
    // POST-MVP（仅占位，本期不实现 UI）：
    // case code
    // case formula
    // case image
    // case quote
}
