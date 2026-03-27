//
//  PageRepositoryProtocol.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation

protocol PageRepositoryProtocol {
    func fetchAll(in collectionID: UUID) throws -> [Page]
    func fetch(by id: UUID) throws -> Page?
    func create(_ page: Page) throws
    func update(_ page: Page) throws
    func delete(by id: UUID) throws
}
