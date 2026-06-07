//
//  BlockAlignment.swift
//  Notte
//
//  Created by 余哲源 on 2026/6/3.
//

import Foundation

/// 图片 Block 在其自身块内的水平对齐。Notte 私有渲染属性，存 SwiftData，不写入 .md。
/// 仅决定图片在块内的水平位置，绝不触发文字绕排（no float / no text wrap）；
/// 缩小后留下的空白属于该块本身，下一个块仍另起一行从左开始。
enum BlockAlignment: String, Codable, Hashable {
    case left
    case center
    case right
}
