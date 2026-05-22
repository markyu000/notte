import XCTest
@testable import Notte

@MainActor
final class NodeMutationServiceDeleteTests: XCTestCase {

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

    private func makeBlock(nodeID: UUID) -> Block {
        Block(
            id: UUID(),
            nodeID: nodeID,
            type: .text,
            content: "",
            sortIndex: 1000,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - delete Tests

    /// 测试：删除单个节点
    func testDeleteSingleNode() async throws {
        let node = makeNode(sortIndex: 1000)
        nodeRepository.storedNodes = [node]

        try await mutationService.delete(nodeID: node.id, in: pageID)

        XCTAssertTrue(nodeRepository.storedNodes.isEmpty)
    }

    /// 测试：删除节点时级联删除其 Block
    func testDeleteCascadesBlocks() async throws {
        let node = makeNode(sortIndex: 1000)
        let block = makeBlock(nodeID: node.id)
        nodeRepository.storedNodes = [node]
        blockRepository.storedBlocks = [block]

        try await mutationService.delete(nodeID: node.id, in: pageID)

        XCTAssertTrue(blockRepository.storedBlocks.isEmpty)
    }

    /// 测试：删除节点时级联删除所有子节点
    func testDeleteCascadesChildren() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let childID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let child = makeNode(id: childID, parentNodeID: parentID, depth: 1, sortIndex: 2000)
        nodeRepository.storedNodes = [parent, child]

        try await mutationService.delete(nodeID: parentID, in: pageID)

        XCTAssertTrue(nodeRepository.storedNodes.isEmpty)
    }

    /// 测试：删除节点时级联删除所有子孙节点及其 Block
    func testDeleteCascadesGrandchildrenAndTheirBlocks() async throws {
        let parentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let childID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let grandchildID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        let parent = makeNode(id: parentID, sortIndex: 1000)
        let child = makeNode(id: childID, parentNodeID: parentID, depth: 1, sortIndex: 2000)
        let grandchild = makeNode(id: grandchildID, parentNodeID: childID, depth: 2, sortIndex: 3000)
        let grandchildBlock = makeBlock(nodeID: grandchildID)

        nodeRepository.storedNodes = [parent, child, grandchild]
        blockRepository.storedBlocks = [grandchildBlock]

        try await mutationService.delete(nodeID: parentID, in: pageID)

        XCTAssertTrue(nodeRepository.storedNodes.isEmpty)
        XCTAssertTrue(blockRepository.storedBlocks.isEmpty)
    }

    /// 测试：删除某节点不影响其同级节点
    func testDeleteDoesNotAffectSiblings() async throws {
        let node1ID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let node2ID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let node1 = makeNode(id: node1ID, sortIndex: 1000)
        let node2 = makeNode(id: node2ID, sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        try await mutationService.delete(nodeID: node1ID, in: pageID)

        XCTAssertEqual(nodeRepository.storedNodes.count, 1)
        XCTAssertEqual(nodeRepository.storedNodes[0].id, node2ID)
    }

    /// 测试：找不到节点时抛出错误
    func testDeleteThrowsWhenNodeNotFound() async {
        do {
            try await mutationService.delete(nodeID: UUID(), in: pageID)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
