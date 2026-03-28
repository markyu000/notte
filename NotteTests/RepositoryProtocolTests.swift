//
//  RepositoryProtocolTests.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/28.
//

import XCTest
import SwiftData
@testable import Notte

final class RepositoryProtocolTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    func testCollectionRepositoryConformsToProtocol() {
        let repo: any CollectionRepositoryProtocol = CollectionRepository(context: context)
        XCTAssertNotNil(repo)
    }

    func testPageRepositoryConformsToProtocol() {
        let repo: any PageRepositoryProtocol = PageRepository(context: context)
        XCTAssertNotNil(repo)
    }

    func testNodeRepositoryConformsToProtocol() {
        let repo: any NodeRepositoryProtocol = NodeRepository(context: context)
        XCTAssertNotNil(repo)
    }

    func testBlockRepositoryConformsToProtocol() {
        let repo: any BlockRepositoryProtocol = BlockRepository(context: context)
        XCTAssertNotNil(repo)
    }
}
