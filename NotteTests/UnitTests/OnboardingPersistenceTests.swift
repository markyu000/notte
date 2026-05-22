//
//  OnboardingPersistenceTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/15.
//

import XCTest
@testable import Notte

@MainActor
final class OnboardingPersistenceTests: XCTestCase {

    private let key = "hasCompletedOnboarding"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    /// 测试：默认值为 false，首次启动需要展示引导
    func testDefaultIsFalse() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: key))
    }

    /// 测试：写入 true 后跨实例读取保持为 true
    func testFlagPersistsAcrossReads() {
        UserDefaults.standard.set(true, forKey: key)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key))
    }
}
