//
//  SortIndexPersistable.swift
//  Notte
//
//  Created by 余哲源 on 2026/7/20.
//

import Foundation

protocol SortIndexPersistable: AnyObject {
    associatedtype Domain: SortIndexable
    nonisolated var id: UUID { get }
    nonisolated var sortIndex: Double { get set }
    nonisolated var updatedAt: Date { get set }
    nonisolated func toDomain() -> Domain
}
