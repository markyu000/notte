//
//  SettingsViewModelTests.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/15.
//

import XCTest
@testable import Notte

@MainActor
final class SettingsViewModelTests: XCTestCase {

    /// 测试：版本号从 Bundle 读出后格式为 "<version> (<build>)"
    func testAppVersionFormat() {
        let vm = SettingsViewModel()
        XCTAssertTrue(vm.appVersion.contains("("))
        XCTAssertTrue(vm.appVersion.hasSuffix(")"))
        XCTAssertFalse(vm.appVersion.contains("0.0.0 (0)"), "未读取到 Bundle 版本号")
    }
}
