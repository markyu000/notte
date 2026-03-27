//
//  BlockRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol BlockRepositoryProtocol {
    func fetchAll(in nodeID: UUID) throws -> [Block]
    func fetch(by id: UUID) throws -> Block?
    func create(_ block: Block) throws
    func update(_ block: Block) throws
    func delete(by id: UUID) throws
    func deleteAll(in nodeID: UUID) throws
}
