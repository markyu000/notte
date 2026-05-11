import XCTest
@testable import Notte

@MainActor
final class PageEditorViewModelPerformanceTests: XCTestCase {

    let pageID = UUID()

    /// 测试：加载 100 节点的页面在合理时间内完成
    func testLoadPageWith100Nodes() async {
        let nodeRepository = MockNodeRepository()
        let blockRepository = MockBlockRepository()
        nodeRepository.storedNodes = (0..<100).map { i in
            Node(
                id: UUID(),
                pageID: pageID,
                parentNodeID: nil,
                title: "Node \(i)",
                depth: 0,
                sortIndex: Double(i) * 1000,
                isCollapsed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        let viewModel = PageEditorViewModel(
            pageID: pageID,
            pageTitle: "Long",
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )

        let start = Date()
        await viewModel.loadPage()
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(viewModel.visibleNodes.count, 100)
        XCTAssertLessThan(elapsed, 0.5, "100 节点加载应在 500ms 内完成")
    }
}
