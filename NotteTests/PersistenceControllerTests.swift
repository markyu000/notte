//
//  PersistenceControllerTests.swift
//  NotteTests
//
//  Created by yuzheyuan on 2026/3/28.
//

import XCTest
import SwiftData
@testable import Notte

final class PersistenceControllerTests: XCTestCase {
    func testContainerInitializesSuccessfully() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        XCTAssertNotNil(container)
    }

    func testModelContextIsAvailable() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        XCTAssertNotNil(context)
    }
}
