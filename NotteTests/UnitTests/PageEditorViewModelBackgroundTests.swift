import XCTest
import UIKit
@testable import Notte

@MainActor
final class PageEditorViewModelBackgroundTests: XCTestCase {

    let pageID = UUID()

    /// 测试：ViewModel 内部订阅 willResignActiveNotification，
    /// 发出通知后 flush() 应将队列内容写入 Repository。
    func testBackgroundNotificationTriggersFlush() async throws {
        let nodeRepository = MockNodeRepository()
        let blockRepository = MockBlockRepository()
        let nodeID = UUID()
        nodeRepository.storedNodes = [
            Node(
                id: nodeID,
                pageID: pageID,
                parentNodeID: nil,
                title: "",
                depth: 0,
                sortIndex: 1000,
                isCollapsed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        let viewModel = PageEditorViewModel(
            pageID: pageID,
            pageTitle: "Test",
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
        await viewModel.loadPage()

        viewModel.onTitleChanged(nodeID: nodeID, title: "background")

        NotificationCenter.default.post(
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        try await Task.sleep(for: .milliseconds(100))

        let updated = try await nodeRepository.fetch(by: nodeID)
        XCTAssertEqual(updated?.title, "background")
    }
}
