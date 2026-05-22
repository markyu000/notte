import XCTest
@testable import Notte

final class NodeQueryServiceTests: XCTestCase {

    var queryService: NodeQueryService!

    override func setUp() {
        super.setUp()
        queryService = NodeQueryService()
    }

    // MARK: - buildTree Tests

    /// 测试：空节点列表构建树
    func testBuildTreeWithEmptyNodes() {
        let nodes: [Node] = []
        let blocks: [Block] = []

        let tree = queryService.buildTree(nodes: nodes, blocks: blocks)

        XCTAssertTrue(tree.isEmpty)
    }

    /// 测试：单个根节点构建树
    func testBuildTreeWithSingleRoot() {
        let node1 = Node(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            pageID: UUID(),
            parentNodeID: nil,
            title: "Root",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let editorNode = queryService.buildTree(nodes: [node1], blocks: []).first

        XCTAssertNotNil(editorNode)
        XCTAssertEqual(editorNode?.id, node1.id)
        XCTAssertEqual(editorNode?.title, "Root")
        XCTAssertEqual(editorNode?.depth, 0)
        XCTAssertTrue(editorNode?.children.isEmpty ?? false)
    }

    /// 测试：多个根节点按 sortIndex 排序
    func testBuildTreeWithMultipleRootsOrderedBySortIndex() {
        let node1 = Node(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            pageID: UUID(),
            parentNodeID: nil,
            title: "First",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let node2 = Node(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            pageID: UUID(),
            parentNodeID: nil,
            title: "Second",
            depth: 0,
            sortIndex: 2000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let tree = queryService.buildTree(nodes: [node2, node1], blocks: [])

        XCTAssertEqual(tree.count, 2)
        XCTAssertEqual(tree[0].id, node1.id)
        XCTAssertEqual(tree[1].id, node2.id)
    }

    /// 测试：二级嵌套结构
    func testBuildTreeWithTwoLevels() {
        let rootID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let childID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let root = Node(
            id: rootID,
            pageID: UUID(),
            parentNodeID: nil,
            title: "Root",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let child = Node(
            id: childID,
            pageID: UUID(),
            parentNodeID: rootID,
            title: "Child",
            depth: 1,
            sortIndex: 1500,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let tree = queryService.buildTree(nodes: [root, child], blocks: [])

        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].children.count, 1)
        XCTAssertEqual(tree[0].children[0].id, childID)
    }

    /// 测试：三级嵌套结构（关键：测试之前的 bug fix）
    func testBuildTreeWithThreeLevels() {
        let rootID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let child1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let grandchildID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        let root = Node(
            id: rootID,
            pageID: UUID(),
            parentNodeID: nil,
            title: "Root",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let child = Node(
            id: child1ID,
            pageID: UUID(),
            parentNodeID: rootID,
            title: "Child",
            depth: 1,
            sortIndex: 1500,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let grandchild = Node(
            id: grandchildID,
            pageID: UUID(),
            parentNodeID: child1ID,
            title: "Grandchild",
            depth: 2,
            sortIndex: 1750,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let tree = queryService.buildTree(nodes: [root, child, grandchild], blocks: [])

        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].children.count, 1)
        XCTAssertEqual(tree[0].children[0].children.count, 1, "grandchild 应该在 child 的 children 中")
        XCTAssertEqual(tree[0].children[0].children[0].id, grandchildID)
    }

    /// 测试：多个子节点按 sortIndex 排序
    func testBuildTreeWithMultipleChildrenOrdering() {
        let rootID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let child1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let child2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        let root = Node(
            id: rootID,
            pageID: UUID(),
            parentNodeID: nil,
            title: "Root",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let child1 = Node(
            id: child1ID,
            pageID: UUID(),
            parentNodeID: rootID,
            title: "Child 1",
            depth: 1,
            sortIndex: 2000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let child2 = Node(
            id: child2ID,
            pageID: UUID(),
            parentNodeID: rootID,
            title: "Child 2",
            depth: 1,
            sortIndex: 1500,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let tree = queryService.buildTree(nodes: [root, child1, child2], blocks: [])

        XCTAssertEqual(tree[0].children.count, 2)
        XCTAssertEqual(tree[0].children[0].id, child2ID, "sortIndex 较小的 child 应该在前")
        XCTAssertEqual(tree[0].children[1].id, child1ID)
    }

    /// 测试：带 Block 的节点
    func testBuildTreeWithBlocks() {
        let nodeID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let blockID1 = UUID(uuidString: "00000000-0000-0000-0000-000000000100")!
        let blockID2 = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!

        let node = Node(
            id: nodeID,
            pageID: UUID(),
            parentNodeID: nil,
            title: "Root",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let block1 = Block(
            id: blockID1,
            nodeID: nodeID,
            type: .text,
            content: "Block 1",
            sortIndex: 1000,
            createdAt: Date(),
            updatedAt: Date()
        )
        let block2 = Block(
            id: blockID2,
            nodeID: nodeID,
            type: .text,
            content: "Block 2",
            sortIndex: 2000,
            createdAt: Date(),
            updatedAt: Date()
        )

        let tree = queryService.buildTree(nodes: [node], blocks: [block2, block1])

        XCTAssertEqual(tree[0].blocks.count, 2)
        XCTAssertEqual(tree[0].blocks[0].id, blockID1, "Block 按 sortIndex 排序")
        XCTAssertEqual(tree[0].blocks[1].id, blockID2)
    }
}
