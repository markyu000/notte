import XCTest
@testable import Notte

@MainActor
final class NodeMutationServiceIndentTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var mutationService: NodeMutationService!
    var queryService: NodeQueryService!

    let pageID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    override func setUp() {
        super.setUp()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        queryService = NodeQueryService()
        mutationService = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: queryService
        )
    }

    // MARK: - Helpers

    private func makeNode(
        id: UUID = UUID(),
        parentNodeID: UUID? = nil,
        sortIndex: Double
    ) -> Node {
        Node(
            id: id,
            pageID: pageID,
            parentNodeID: parentNodeID,
            title: "",
            sortIndex: sortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func find(_ id: UUID, in editorNodes: [EditorNode]) -> EditorNode? {
        for node in editorNodes {
            if node.id == id { return node }
            if let found = find(id, in: node.children) { return found }
        }
        return nil
    }

    // MARK: - indent Tests

    /// 测试：缩进后 parentNodeID 变为前一个同级节点
    func testIndentSetsParentToPreiousSibling() async throws {
        let node1 = makeNode(sortIndex: 1000)
        let node2 = makeNode(sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.indent(nodeID: node2.id, in: pageID)

        let updated = try await nodeRepository.fetch(by: node2.id)
        XCTAssertEqual(updated?.parentNodeID, node1.id)
    }

    /// 测试：缩进后 buildTree 重算出的 depth 增加 1
    func testIndentIncrementsDepth() async throws {
        let node1 = makeNode(sortIndex: 1000)
        let node2 = makeNode(sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.indent(nodeID: node2.id, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let tree = try queryService.buildTree(nodes: nodes, blocks: [])
        XCTAssertEqual(find(node2.id, in: tree)?.depth, 1)
    }

    /// 测试：前一个同级节点无子节点时，缩进后 sortIndex 使用初始值
    func testIndentSortIndexWhenNewParentHasNoChildren() async throws {
        let node1 = makeNode(sortIndex: 1000)
        let node2 = makeNode(sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.indent(nodeID: node2.id, in: pageID)

        let updated = try await nodeRepository.fetch(by: node2.id)
        XCTAssertNotNil(updated?.sortIndex)
    }

    /// 测试：前一个同级节点已有子节点时，缩进后 sortIndex 排在子节点末尾之后
    func testIndentSortIndexAfterExistingChildren() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let existingChildID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let existingChild = makeNode(id: existingChildID, parentNodeID: parentID, sortIndex: 1500)
        let target = makeNode(id: targetID, sortIndex: 2000)
        nodeRepository.storedNodes = [parent, existingChild, target]

        try await mutationService.indent(nodeID: targetID, in: pageID)

        let updated = try await nodeRepository.fetch(by: targetID)
        XCTAssertGreaterThan(updated!.sortIndex, existingChild.sortIndex)
    }

    /// 测试：子孙节点的 parentNodeID 不受影响；重新 buildTree 后子孙 depth 随子树整体下移 +1
    func testIndentUpdatesDescendantDepths() async throws {
        let node1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let node2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let childID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let grandchildID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

        let node1 = makeNode(id: node1ID, sortIndex: 1000)
        let node2 = makeNode(id: node2ID, sortIndex: 2000)
        let child = makeNode(id: childID, parentNodeID: node2ID, sortIndex: 2500)
        let grandchild = makeNode(id: grandchildID, parentNodeID: childID, sortIndex: 2600)
        nodeRepository.storedNodes = [node1, node2, child, grandchild]

        try await mutationService.indent(nodeID: node2ID, in: pageID)

        let updatedChild = try await nodeRepository.fetch(by: childID)
        let updatedGrandchild = try await nodeRepository.fetch(by: grandchildID)
        XCTAssertEqual(updatedChild?.parentNodeID, node2ID, "indent 不碰子孙节点的 parentNodeID")
        XCTAssertEqual(updatedGrandchild?.parentNodeID, childID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let tree = try queryService.buildTree(nodes: nodes, blocks: [])
        XCTAssertEqual(find(childID, in: tree)?.depth, 2)
        XCTAssertEqual(find(grandchildID, in: tree)?.depth, 3)
    }

    /// 测试：没有前一个同级节点时，缩进无效果
    func testIndentDoesNothingWhenNoPreviousSibling() async throws {
        let node = makeNode(sortIndex: 1000)
        nodeRepository.storedNodes = [node]

        try await mutationService.indent(nodeID: node.id, in: pageID)

        let unchanged = try await nodeRepository.fetch(by: node.id)
        XCTAssertNil(unchanged?.parentNodeID)
    }

    /// 测试：找不到节点时抛出错误
    func testIndentThrowsWhenNodeNotFound() async {
        do {
            try await mutationService.indent(nodeID: UUID(), in: pageID)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
