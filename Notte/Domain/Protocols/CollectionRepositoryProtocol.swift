//
//  CollectionRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol CollectionRepositoryProtocol {
    func fetchAll() throws -> [Collection]
    func fetch(by id: UUID) throws -> Collection?
    func create(_ collection: Collection) throws
    func update(_ colleciton: Collection) throws
    func delete(by id: UUID) throws
}
