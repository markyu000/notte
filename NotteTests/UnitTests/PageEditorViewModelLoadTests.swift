import XCTest
@testable import Notte

@MainActor
final class PageEditorViewModelLoadTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var viewModel: PageEditorViewModel!

    let pageID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    override func setUp() {
        super.setUp()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        viewModel = PageEditorViewModel(
            pageID: pageID,
            pageTitle: "Test Page",
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
    }

    private func makeNode(
        id: UUID = UUID(),
        parentNodeID: UUID? = nil,
        depth: Int = 0,
        sortIndex: Double
    ) -> Node {
        Node(
            id: id,
            pageID: pageID,
            parentNodeID: parentNodeID,
            title: "Node",
            depth: depth,
            sortIndex: sortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - loadPage Tests

    /// 测试：空页面加载后 visibleNodes 为空
    func testLoadPageWithNoNodes() async {
        await viewModel.loadPage()

        XCTAssertTrue(viewModel.visibleNodes.isEmpty)
    }

    /// 测试：加载后 visibleNodes 包含正确数量的节点
    func testLoadPageWithMultipleNodes() async {
        nodeRepository.storedNodes = [
            makeNode(sortIndex: 1000),
            makeNode(sortIndex: 2000),
            makeNode(sortIndex: 3000)
        ]

        await viewModel.loadPage()

        XCTAssertEqual(viewModel.visibleNodes.count, 3)
    }

    /// 测试：加载后 visibleNodes 按 sortIndex 排序
    func testLoadPageNodesOrderedBySortIndex() async {
        let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        nodeRepository.storedNodes = [
            makeNode(id: id2, sortIndex: 2000),
            makeNode(id: id1, sortIndex: 1000)
        ]

        await viewModel.loadPage()

        XCTAssertEqual(viewModel.visibleNodes[0].id, id1)
        XCTAssertEqual(viewModel.visibleNodes[1].id, id2)
    }

    /// 测试：折叠节点的子节点不出现在 visibleNodes 中
    func testLoadPageCollapsedNodeChildrenNotVisible() async {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let childID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        var parent = makeNode(id: parentID, sortIndex: 1000)
        parent.isCollapsed = true
        let child = makeNode(id: childID, parentNodeID: parentID, depth: 1, sortIndex: 1500)
        nodeRepository.storedNodes = [parent, child]

        await viewModel.loadPage()

        XCTAssertEqual(viewModel.visibleNodes.count, 1)
        XCTAssertEqual(viewModel.visibleNodes[0].id, parentID)
    }

    /// 测试：加载后 visibleNodes 包含正确 depth
    func testLoadPageNodesHaveCorrectDepth() async {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let childID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let parent = makeNode(id: parentID, depth: 0, sortIndex: 1000)
        let child = makeNode(id: childID, parentNodeID: parentID, depth: 1, sortIndex: 1500)
        nodeRepository.storedNodes = [parent, child]

        await viewModel.loadPage()

        XCTAssertEqual(viewModel.visibleNodes.first(where: { $0.id == parentID })?.depth, 0)
        XCTAssertEqual(viewModel.visibleNodes.first(where: { $0.id == childID })?.depth, 1)
    }
}
