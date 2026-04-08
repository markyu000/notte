//
//  NodeRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol NodeRepositoryProtocol {
    func fetchAll(in pageID: UUID) async throws -> [Node]
    func fetch(by id: UUID) async throws -> Node?
    func create(_ node: Node) async throws
    func update(_ node: Node) async throws
    func delete(by id: UUID) async throws
    func deleteAll(in pageID: UUID) async throws
}
