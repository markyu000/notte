import XCTest
@testable import Notte

@MainActor
final class NodeMutationServiceMoveTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var mutationService: NodeMutationService!

    let pageID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    override func setUp() {
        super.setUp()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        mutationService = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
    }

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
            depth: 0,
            sortIndex: sortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - moveUp Tests

    /// 测试：上移后与前一个同级节点交换 sortIndex
    func testMoveUpSwapsSortIndex() async throws {
        let node1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let node2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let node1 = makeNode(id: node1ID, sortIndex: 1000)
        let node2 = makeNode(id: node2ID, sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.moveUp(nodeID: node2ID, in: pageID)

        let updated1 = try await nodeRepository.fetch(by: node1ID)
        let updated2 = try await nodeRepository.fetch(by: node2ID)
        XCTAssertEqual(updated2?.sortIndex, 1000)
        XCTAssertEqual(updated1?.sortIndex, 2000)
    }

    /// 测试：已在同级第一位时 moveUp 无效果
    func testMoveUpDoesNothingWhenAlreadyFirst() async throws {
        let node1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let node2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let node1 = makeNode(id: node1ID, sortIndex: 1000)
        let node2 = makeNode(id: node2ID, sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.moveUp(nodeID: node1ID, in: pageID)

        let unchanged = try await nodeRepository.fetch(by: node1ID)
        XCTAssertEqual(unchanged?.sortIndex, 1000)
    }

    /// 测试：moveUp 只与同级节点交换，不影响其他层级
    func testMoveUpOnlyAffectsSiblings() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let child1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let child2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let rootID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

        let root = makeNode(id: rootID, sortIndex: 500)
        let parent = makeNode(id: parentID, sortIndex: 1000)
        let child1 = makeNode(id: child1ID, parentNodeID: parentID, sortIndex: 1500)
        let child2 = makeNode(id: child2ID, parentNodeID: parentID, sortIndex: 2000)
        nodeRepository.storedNodes = [root, parent, child1, child2]

        try await mutationService.moveUp(nodeID: child2ID, in: pageID)

        let unchangedRoot = try await nodeRepository.fetch(by: rootID)
        let unchangedParent = try await nodeRepository.fetch(by: parentID)
        XCTAssertEqual(unchangedRoot?.sortIndex, 500)
        XCTAssertEqual(unchangedParent?.sortIndex, 1000)
    }

    // MARK: - moveDown Tests

    /// 测试：下移后与后一个同级节点交换 sortIndex
    func testMoveDownSwapsSortIndex() async throws {
        let node1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let node2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let node1 = makeNode(id: node1ID, sortIndex: 1000)
        let node2 = makeNode(id: node2ID, sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.moveDown(nodeID: node1ID, in: pageID)

        let updated1 = try await nodeRepository.fetch(by: node1ID)
        let updated2 = try await nodeRepository.fetch(by: node2ID)
        XCTAssertEqual(updated1?.sortIndex, 2000)
        XCTAssertEqual(updated2?.sortIndex, 1000)
    }

    /// 测试：已在同级最后一位时 moveDown 无效果
    func testMoveDownDoesNothingWhenAlreadyLast() async throws {
        let node1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let node2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let node1 = makeNode(id: node1ID, sortIndex: 1000)
        let node2 = makeNode(id: node2ID, sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.moveDown(nodeID: node2ID, in: pageID)

        let unchanged = try await nodeRepository.fetch(by: node2ID)
        XCTAssertEqual(unchanged?.sortIndex, 2000)
    }

    /// 测试：找不到节点时 moveUp 抛出错误
    func testMoveUpThrowsWhenNodeNotFound() async {
        do {
            try await mutationService.moveUp(nodeID: UUID(), in: pageID)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    /// 测试：找不到节点时 moveDown 抛出错误
    func testMoveDownThrowsWhenNodeNotFound() async {
        do {
            try await mutationService.moveDown(nodeID: UUID(), in: pageID)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
