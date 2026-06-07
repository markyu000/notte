//
//  ImageWidthRatio.swift
//  Notte
//
//  Created by 余哲源 on 2026/6/3.
//

import Foundation

/// 图片 Block 的显示宽度比例。Notte 私有渲染属性，存 SwiftData，不写入 .md。
/// 解决 Markdown 图片独占整行、过大突兀或过小留白的痛点。
enum ImageWidthRatio: String, Codable, Hashable {
    case full
    case half
    case third

    /// 相对所在内容宽度的占比。
    var fraction: Double {
        switch self {
        case .full: return 1.0
        case .half: return 0.5
        case .third: return 1.0 / 3.0
        }
    }
}
