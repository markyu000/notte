//
//  NodeRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol NodeRepositoryProtocol {
    func fetchAll(in pageID: UUID) throws -> [Node]
    func fetch(by id: UUID) throws -> Node?
    func create(_ node: Node) throws
    func update(_ node: Node) throws
    func delete(by id: UUID) throws
    func deleteAll(in pageID: UUID) throws
}
