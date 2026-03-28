//
//  Block.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/25.
//

import Foundation

struct Block: Identifiable, Hashable {
    let id: UUID
    let nodeID: UUID
    var type: BlockType
    var content: String
    var sortIndex: Double
    var createdAt: Date
    var updatedAt: Date
}
