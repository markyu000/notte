import XCTest
@testable import Notte

final class NodeQueryServiceVisibleNodesTests: XCTestCase {

    var queryService: NodeQueryService!

    override func setUp() {
        super.setUp()
        queryService = NodeQueryService()
    }

    // MARK: - Helpers

    private func makeNode(
        id: UUID = UUID(),
        title: String = "",
        depth: Int = 0,
        sortIndex: Double = 1000,
        isCollapsed: Bool = false,
        children: [EditorNode] = []
    ) -> EditorNode {
        EditorNode(
            id: id,
            title: title,
            depth: depth,
            sortIndex: sortIndex,
            isCollapsed: isCollapsed,
            children: children
        )
    }

    // MARK: - visibleNodes Tests

    /// 测试：空树返回空列表
    func testVisibleNodesWithEmptyTree() {
        let result = queryService.visibleNodes(from: [])

        XCTAssertTrue(result.isEmpty)
    }

    /// 测试：单个根节点可见
    func testVisibleNodesWithSingleRoot() {
        let root = makeNode(title: "Root")

        let result = queryService.visibleNodes(from: [root])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, root.id)
    }

    /// 测试：未折叠时子节点可见
    func testVisibleNodesWithExpandedParent() {
        let childID = UUID()
        let child = makeNode(id: childID, title: "Child", depth: 1)
        let root = makeNode(title: "Root", isCollapsed: false, children: [child])

        let result = queryService.visibleNodes(from: [root])

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, root.id)
        XCTAssertEqual(result[1].id, childID)
    }

    /// 测试：折叠时子节点不可见
    func testVisibleNodesWithCollapsedParent() {
        let child = makeNode(title: "Child", depth: 1)
        let root = makeNode(title: "Root", isCollapsed: true, children: [child])

        let result = queryService.visibleNodes(from: [root])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, root.id)
    }

    /// 测试：折叠时孙节点也不可见
    func testVisibleNodesWithCollapsedParentHidesGrandchildren() {
        let grandchild = makeNode(title: "Grandchild", depth: 2)
        let child = makeNode(title: "Child", depth: 1, isCollapsed: false, children: [grandchild])
        let root = makeNode(title: "Root", isCollapsed: true, children: [child])

        let result = queryService.visibleNodes(from: [root])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, root.id)
    }

    /// 测试：深度优先前序遍历顺序
    func testVisibleNodesDepthFirstOrder() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()

        let grandchild = makeNode(id: id3, title: "Grandchild", depth: 2)
        let child1 = makeNode(id: id2, title: "Child1", depth: 1, children: [grandchild])
        let child2 = makeNode(id: id4, title: "Child2", depth: 1)
        let root = makeNode(id: id1, title: "Root", children: [child1, child2])

        let result = queryService.visibleNodes(from: [root])

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].id, id1) // Root
        XCTAssertEqual(result[1].id, id2) // Child1
        XCTAssertEqual(result[2].id, id3) // Grandchild
        XCTAssertEqual(result[3].id, id4) // Child2
    }

    /// 测试：中间层折叠时只隐藏其子树
    func testVisibleNodesWithMiddleLevelCollapsed() {
        let grandchild = makeNode(title: "Grandchild", depth: 2)
        let child1 = makeNode(title: "Child1", depth: 1, isCollapsed: true, children: [grandchild])
        let child2 = makeNode(title: "Child2", depth: 1)
        let root = makeNode(title: "Root", children: [child1, child2])

        let result = queryService.visibleNodes(from: [root])

        XCTAssertEqual(result.count, 3) // Root + Child1 + Child2，Grandchild 不可见
        XCTAssertFalse(result.map(\.title).contains("Grandchild"))
    }

    /// 测试：所有节点的 isVisible 被设置为 true
    func testVisibleNodesSetIsVisibleFlag() {
        let child = makeNode(title: "Child", depth: 1, isCollapsed: false)
        let root = makeNode(title: "Root", children: [child])

        let result = queryService.visibleNodes(from: [root])

        XCTAssertTrue(result.allSatisfy(\.isVisible))
    }
}
