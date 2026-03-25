//
//  CollectionModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

@Model
class CollectionModel {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var iconName: String? = nil
    var colorToken: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortIndex: Double = 0
    var isPinned: Bool = false

    init() {}
}
