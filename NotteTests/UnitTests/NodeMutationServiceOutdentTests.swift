import XCTest
@testable import Notte

@MainActor
final class NodeMutationServiceOutdentTests: XCTestCase {

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

    // MARK: - outdent Tests

    /// 测试：反缩进后 parentNodeID 变为祖父节点
    func testOutdentSetsParentToGrandparent() async throws {
        let rootID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        let root = makeNode(id: rootID, sortIndex: 1000)
        let parent = makeNode(id: parentID, parentNodeID: rootID, sortIndex: 2000)
        let target = makeNode(id: targetID, parentNodeID: parentID, sortIndex: 3000)
        nodeRepository.storedNodes = [root, parent, target]

        try await mutationService.outdent(nodeID: targetID, in: pageID)

        let updated = try await nodeRepository.fetch(by: targetID)
        XCTAssertEqual(updated?.parentNodeID, rootID)
    }

    /// 测试：反缩进后 parentNodeID 变为 nil（从二级到根）
    func testOutdentToRootSetsParentToNil() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let target = makeNode(id: targetID, parentNodeID: parentID, sortIndex: 2000)
        nodeRepository.storedNodes = [parent, target]

        try await mutationService.outdent(nodeID: targetID, in: pageID)

        let updated = try await nodeRepository.fetch(by: targetID)
        XCTAssertNil(updated?.parentNodeID)
    }

    /// 测试：反缩进后 buildTree 重算出的 depth 减少 1
    func testOutdentDecrementsDepth() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let target = makeNode(id: targetID, parentNodeID: parentID, sortIndex: 2000)
        nodeRepository.storedNodes = [parent, target]

        try await mutationService.outdent(nodeID: targetID, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let tree = try queryService.buildTree(nodes: nodes, blocks: [])
        let updated = tree.first { $0.id == targetID }
        XCTAssertEqual(updated?.depth, 0)
    }

    /// 测试：反缩进后 sortIndex 在原父节点之后
    func testOutdentSortIndexAfterOriginalParent() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let target = makeNode(id: targetID, parentNodeID: parentID, sortIndex: 2000)
        nodeRepository.storedNodes = [parent, target]

        try await mutationService.outdent(nodeID: targetID, in: pageID)

        let updated = try await nodeRepository.fetch(by: targetID)
        XCTAssertGreaterThan(updated!.sortIndex, parent.sortIndex)
    }

    /// 测试：反缩进后 sortIndex 在原父节点下一个同级节点之前
    func testOutdentSortIndexBetweenParentAndParentNextSibling() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let parentNextID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let target = makeNode(id: targetID, parentNodeID: parentID, sortIndex: 1500)
        let parentNext = makeNode(id: parentNextID, sortIndex: 2000)
        nodeRepository.storedNodes = [parent, target, parentNext]

        try await mutationService.outdent(nodeID: targetID, in: pageID)

        let updated = try await nodeRepository.fetch(by: targetID)
        XCTAssertGreaterThan(updated!.sortIndex, parent.sortIndex)
        XCTAssertLessThan(updated!.sortIndex, parentNext.sortIndex)
    }

    /// 测试：子孙节点的 parentNodeID 不受影响；重新 buildTree 后子孙 depth 随子树整体下移 -1
    func testOutdentUpdatesDescendantDepths() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let childID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let grandchildID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let target = makeNode(id: targetID, parentNodeID: parentID, sortIndex: 2000)
        let child = makeNode(id: childID, parentNodeID: targetID, sortIndex: 2500)
        let grandchild = makeNode(id: grandchildID, parentNodeID: childID, sortIndex: 2600)
        nodeRepository.storedNodes = [parent, target, child, grandchild]

        try await mutationService.outdent(nodeID: targetID, in: pageID)

        let updatedChild = try await nodeRepository.fetch(by: childID)
        let updatedGrandchild = try await nodeRepository.fetch(by: grandchildID)
        XCTAssertEqual(updatedChild?.parentNodeID, targetID, "outdent 不碰子孙节点的 parentNodeID")
        XCTAssertEqual(updatedGrandchild?.parentNodeID, childID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let tree = try queryService.buildTree(nodes: nodes, blocks: [])
        func find(_ id: UUID, in editorNodes: [EditorNode]) -> EditorNode? {
            for node in editorNodes {
                if node.id == id { return node }
                if let found = find(id, in: node.children) { return found }
            }
            return nil
        }
        XCTAssertEqual(find(childID, in: tree)?.depth, 1)
        XCTAssertEqual(find(grandchildID, in: tree)?.depth, 2)
    }

    /// 测试：已在根层时无效果
    func testOutdentDoesNothingWhenAlreadyAtRoot() async throws {
        let target = makeNode(sortIndex: 1000)
        nodeRepository.storedNodes = [target]

        try await mutationService.outdent(nodeID: target.id, in: pageID)

        let unchanged = try await nodeRepository.fetch(by: target.id)
        XCTAssertNil(unchanged?.parentNodeID)
    }

    /// 测试：找不到节点时抛出错误
    func testOutdentThrowsWhenNodeNotFound() async {
        do {
            try await mutationService.outdent(nodeID: UUID(), in: pageID)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
