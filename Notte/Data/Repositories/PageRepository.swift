//
//  PageRepository.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/24.
//

import Foundation
import SwiftData

class PageRepository: PageRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in collectionID: UUID) async throws -> [Page] {
        throw RepositoryError.notImplemented
    }

    func fetch(by id: UUID) async throws -> Page? {
        throw RepositoryError.notImplemented
    }

    func create(_ page: Page) async throws {
        throw RepositoryError.notImplemented
    }

    func update(_ page: Page) async throws {
        throw RepositoryError.notImplemented
    }

    func delete(by id: UUID) async throws {
        throw RepositoryError.notImplemented
    }
}
