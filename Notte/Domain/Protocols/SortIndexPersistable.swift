//
//  SortIndexPersistable.swift
//  Notte
//
//  Created by 余哲源 on 2026/7/20.
//

import Foundation

protocol SortIndexPersistable: AnyObject {
    associatedtype Domain: SortIndexable
    var id: UUID { get }
    var sortIndex: Double { get set }
    var updatedAt: Date { get set }
    func toDomain() -> Domain
}
