import XCTest
@testable import Notte

@MainActor
final class NodeMutationServiceInsertAfterTests: XCTestCase {

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

    // MARK: - Helpers

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

    // MARK: - insertAfter Tests

    /// 测试：在唯一节点后插入，新节点 sortIndex 更大
    func testInsertAfterSingleNode() async throws {
        let existing = makeNode(sortIndex: 1000)
        nodeRepository.storedNodes = [existing]

        let newNode = try await mutationService.insertAfter(nodeID: existing.id, in: pageID)

        XCTAssertEqual(nodeRepository.storedNodes.count, 2)
        XCTAssertGreaterThan(newNode.sortIndex, existing.sortIndex)
    }

    /// 测试：新节点继承当前节点的 depth
    func testInsertAfterInheritsDepth() async throws {
        let existing = makeNode(depth: 2, sortIndex: 1000)
        nodeRepository.storedNodes = [existing]

        let newNode = try await mutationService.insertAfter(nodeID: existing.id, in: pageID)

        XCTAssertEqual(newNode.depth, existing.depth)
    }

    /// 测试：新节点继承当前节点的 parentNodeID
    func testInsertAfterInheritsParentNodeID() async throws {
        let parentID = UUID()
        let existing = makeNode(parentNodeID: parentID, sortIndex: 1000)
        nodeRepository.storedNodes = [existing]

        let newNode = try await mutationService.insertAfter(nodeID: existing.id, in: pageID)

        XCTAssertEqual(newNode.parentNodeID, parentID)
    }

    /// 测试：在两节点中间插入，新节点 sortIndex 在两者之间
    func testInsertAfterBetweenTwoNodes() async throws {
        let node1 = makeNode(sortIndex: 1000)
        let node2 = makeNode(sortIndex: 2000)
        nodeRepository.storedNodes = [node1, node2]

        let newNode = try await mutationService.insertAfter(nodeID: node1.id, in: pageID)

        XCTAssertGreaterThan(newNode.sortIndex, node1.sortIndex)
        XCTAssertLessThan(newNode.sortIndex, node2.sortIndex)
    }

    /// 测试：新节点自动创建一个空 text Block
    func testInsertAfterCreatesEmptyBlock() async throws {
        let existing = makeNode(sortIndex: 1000)
        nodeRepository.storedNodes = [existing]

        let newNode = try await mutationService.insertAfter(nodeID: existing.id, in: pageID)

        let blocks = blockRepository.storedBlocks.filter { $0.nodeID == newNode.id }
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].type, .text)
        XCTAssertEqual(blocks[0].content, "")
    }

    /// 测试：找不到节点时抛出错误
    func testInsertAfterThrowsWhenNodeNotFound() async {
        do {
            _ = try await mutationService.insertAfter(nodeID: UUID(), in: pageID)
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    /// 测试：新节点所属 pageID 正确
    func testInsertAfterNewNodeBelongsToCorrectPage() async throws {
        let existing = makeNode(sortIndex: 1000)
        nodeRepository.storedNodes = [existing]

        let newNode = try await mutationService.insertAfter(nodeID: existing.id, in: pageID)

        XCTAssertEqual(newNode.pageID, pageID)
    }
}
