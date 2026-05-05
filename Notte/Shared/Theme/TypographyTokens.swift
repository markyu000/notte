//
//  TypographyTokens.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/28.
//

import SwiftUI
import UIKit

struct TypographyTokens {
    // MARK: - UIFont(数据源)

    static let UIlargeTitle = UIFont.preferredFont(forTextStyle: .largeTitle)
        .rounded().withWeight(.bold)
    static let UItitle = UIFont.systemFont(ofSize: 20, weight: .bold).rounded()
    static let UIsubTitle = UIFont.systemFont(ofSize: 15, weight: .regular).rounded()
    static let UItitle2 = UIFont.systemFont(ofSize: 17, weight: .semibold).rounded()
    static let UIbody = UIFont.preferredFont(forTextStyle: .body)
    static let UIcaption = UIFont.preferredFont(forTextStyle: .caption1)

    // MARK: - Font(从 UIFont 派生)

    static let largeTitle = Font(UIlargeTitle)
    static let title = Font(UItitle)
    static let subTitle = Font(UIsubTitle)
    static let title2 = Font(UItitle2)
    static let body = Font(UIbody)
    static let caption = Font(UIcaption)

    // MARK: - Node 标题

    static func nodeTitleUI(depth: Int) -> UIFont {
        switch depth {
        case 0: return UIFont.preferredFont(forTextStyle: .title1).rounded().withWeight(.bold)
        case 1: return UIFont.preferredFont(forTextStyle: .title2).rounded().withWeight(.semibold)
        case 2: return UIFont.preferredFont(forTextStyle: .title3).rounded().withWeight(.semibold)
        case 3: return UIFont.preferredFont(forTextStyle: .headline)
        case 4: return UIFont.preferredFont(forTextStyle: .subheadline)
        default: return UIFont.preferredFont(forTextStyle: .body)
        }
    }

    static func nodeTitle(depth: Int) -> Font {
        Font(nodeTitleUI(depth: depth))
    }
}

// MARK: - UIFont 辅助

private extension UIFont {
    /// 应用 rounded design,失败时返回原字体
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }

    /// 修改字重,保留尺寸和 design
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight]
        let descriptor = fontDescriptor.addingAttributes([.traits: traits])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
