import XCTest
@testable import Notte

@MainActor
final class PageEditorViewModelDisappearTests: XCTestCase {

    let pageID = UUID()

    /// 测试：onDisappear 调用后队列内容立即写入 Repository
    func testOnDisappearFlushesPendingTitle() async throws {
        let nodeRepository = MockNodeRepository()
        let blockRepository = MockBlockRepository()
        let nodeID = UUID()
        nodeRepository.storedNodes = [
            Node(
                id: nodeID,
                pageID: pageID,
                parentNodeID: nil,
                title: "old",
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

        viewModel.onTitleChanged(nodeID: nodeID, title: "new")
        viewModel.onDisappear()
        try await Task.sleep(for: .milliseconds(100))

        let updated = try await nodeRepository.fetch(by: nodeID)
        XCTAssertEqual(updated?.title, "new")
    }
}
