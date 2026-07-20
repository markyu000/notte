//
//  SortIndexable.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/8.
//

import Foundation

protocol SortIndexable {
    var id: UUID { get }
    var sortIndex: Double { get set }
    var updatedAt: Date { get set }
}
