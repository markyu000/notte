import XCTest
@testable import Notte

@MainActor
final class NodeMutationServiceToggleCollapseTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var mutationService: NodeMutationService!

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

    private func makeNode(id: UUID = UUID(), isCollapsed: Bool) -> Node {
        Node(
            id: id,
            pageID: UUID(),
            parentNodeID: nil,
            title: "",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: isCollapsed,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - toggleCollapse Tests

    /// 测试：展开状态切换后变为折叠
    func testToggleCollapseFromExpandedToCollapsed() async throws {
        let node = makeNode(isCollapsed: false)
        nodeRepository.storedNodes = [node]

        try await mutationService.toggleCollapse(nodeID: node.id)

        let updated = try await nodeRepository.fetch(by: node.id)
        XCTAssertEqual(updated?.isCollapsed, true)
    }

    /// 测试：折叠状态切换后变为展开
    func testToggleCollapseFromCollapsedToExpanded() async throws {
        let node = makeNode(isCollapsed: true)
        nodeRepository.storedNodes = [node]

        try await mutationService.toggleCollapse(nodeID: node.id)

        let updated = try await nodeRepository.fetch(by: node.id)
        XCTAssertEqual(updated?.isCollapsed, false)
    }

    /// 测试：连续两次切换后恢复初始状态
    func testToggleCollapseTwiceRestoresOriginalState() async throws {
        let node = makeNode(isCollapsed: false)
        nodeRepository.storedNodes = [node]

        try await mutationService.toggleCollapse(nodeID: node.id)
        try await mutationService.toggleCollapse(nodeID: node.id)

        let updated = try await nodeRepository.fetch(by: node.id)
        XCTAssertEqual(updated?.isCollapsed, false)
    }

    /// 测试：找不到节点时抛出错误
    func testToggleCollapseThrowsWhenNodeNotFound() async {
        do {
            try await mutationService.toggleCollapse(nodeID: UUID())
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
