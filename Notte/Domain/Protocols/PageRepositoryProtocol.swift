//
//  PageRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol PageRepositoryProtocol {
    func fetchAll(in collectionID: UUID) async throws -> [Page]
    func fetch(by id: UUID) async throws -> Page?
    func create(_ page: Page) async throws
    func update(_ page: Page) async throws
    func delete(by id: UUID) async throws
}
