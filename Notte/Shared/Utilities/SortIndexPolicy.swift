//
//  SortIndexPolicy.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/26.
//

import Foundation

enum SortIndexPolicy {
    static let initialSpacing: Double = 1000
    static let minimumGap: Double = 0.001

    // 生成第一个条目的 sortIndex
    static func initialIndex() -> Double {
        initialSpacing
    }

    // 在所有条目末尾追加时的 sortIndex
    static func indexAfter(last: Double) -> Double {
        last + initialSpacing
    }

    // 在两个条目之间插入时的 sortIndex
    static func indexBetween(before: Double, after: Double) -> Double {
        (before + after) / 2
    }

    // 判断是否需要重新归一化
    static func needsNormalization(before: Double, after: Double) -> Bool {
        (after - before) < minimumGap
    }

    // 重新归一化整个列表的 sortIndex
    static func normalize(count: Int) -> [Double] {
        (1...count).map { Double($0) * initialSpacing }
    }
}
