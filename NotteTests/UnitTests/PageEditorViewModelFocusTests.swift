import XCTest
@testable import Notte

@MainActor
final class PageEditorViewModelFocusTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var viewModel: PageEditorViewModel!

    let pageID = UUID()

    override func setUp() {
        super.setUp()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        viewModel = PageEditorViewModel(
            pageID: pageID,
            pageTitle: "Test",
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
            title: "",
            depth: depth,
            sortIndex: sortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// 测试：delete 命令前，pendingFocusNodeID 指向被删节点的前一个
    func testDeleteSetsPendingFocusToPrevious() async {
        let id1 = UUID()
        let id2 = UUID()
        nodeRepository.storedNodes = [
            makeNode(id: id1, sortIndex: 1000),
            makeNode(id: id2, sortIndex: 2000)
        ]
        await viewModel.loadPage()

        viewModel.send(.delete(nodeID: id2))
        XCTAssertEqual(viewModel.pendingFocusNodeID, id1)
    }

    /// 测试：删除第一个节点时不设置 pendingFocusNodeID
    func testDeleteFirstNodeDoesNotSetFocus() async {
        let id1 = UUID()
        nodeRepository.storedNodes = [makeNode(id: id1, sortIndex: 1000)]
        await viewModel.loadPage()

        viewModel.send(.delete(nodeID: id1))
        XCTAssertNil(viewModel.pendingFocusNodeID)
    }

    /// 测试：删除节点时焦点回到上一个可见节点，即使层级不同
    func testDeleteSetsPendingFocusToPreviousVisibleNodeAcrossLevels() async {
        let rootID = UUID()
        let childID = UUID()
        let nextRootID = UUID()
        nodeRepository.storedNodes = [
            makeNode(id: rootID, sortIndex: 1000),
            makeNode(id: childID, parentNodeID: rootID, depth: 1, sortIndex: 1000),
            makeNode(id: nextRootID, sortIndex: 2000)
        ]
        await viewModel.loadPage()

        viewModel.send(.delete(nodeID: nextRootID))

        XCTAssertEqual(viewModel.pendingFocusNodeID, childID)
    }
}
