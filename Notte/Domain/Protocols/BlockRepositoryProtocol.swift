//
//  BlockRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol BlockRepositoryProtocol {
    func fetchAll(in nodeID: UUID) async throws -> [Block]
    func fetch(by id: UUID) async throws -> Block?
    func create(_ block: Block) async throws
    func update(_ block: Block) async throws
    func delete(by id: UUID) async throws
    func deleteAll(in nodeID: UUID) async throws
}
