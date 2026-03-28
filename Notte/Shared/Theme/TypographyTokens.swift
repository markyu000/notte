//
//  TypographyTokens.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/28.
//

import SwiftUI

struct TypographyTokens {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title2, design: .rounded, weight: .semibold)
    static let body = Font.system(.body)
    static let caption = Font.system(.caption)

    // Node 标题渲染，对应 depth 0-5
    static func nodeTitle(depth: Int) -> Font {
        switch depth {
        case 0: return Font.system(.title, design: .rounded, weight: .bold)
        case 1: return Font.system(.title2, design: .rounded, weight: .semibold)
        case 2: return Font.system(.title3, design: .rounded, weight: .semibold)
        case 3: return Font.system(.headline)
        case 4: return Font.system(.subheadline)
        default: return Font.system(.body)
        }
    }
}
