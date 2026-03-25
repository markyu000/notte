//
//  PageModel.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

@Model
class PageModel {
    var id: UUID = UUID()
    var collectionID: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortIndex: Double = 0
    var isArchived: Bool = false

    init() {}
}
