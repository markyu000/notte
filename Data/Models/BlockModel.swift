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
    var id: UUID = UUID()
    var nodeID: UUID = UUID()
    var type: String = BlockType.text.rawValue
    var content: String = ""
    var sortIndex: Double = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init() {}
}
