//
//  CollectionRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol CollectionRepositoryProtocol {
    func fetchAll() async throws -> [Collection]
    func fetch(by id: UUID) async throws -> Collection?
    func create(_ collection: Collection) async throws
    func update(_ collection: Collection) async throws
    func delete(by id: UUID) async throws
}
