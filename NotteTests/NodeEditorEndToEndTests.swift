import XCTest
import SwiftData
@testable import Notte

/// E2E 测试：使用真实 in-memory SwiftData 容器，验证 create → persist → reload 完整链路。
@MainActor
final class NodeEditorEndToEndTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var nodeRepository: NodeRepository!
    var blockRepository: BlockRepository!
    var mutationService: NodeMutationService!
    var queryService: NodeQueryService!

    let pageID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    override func setUp() {
        super.setUp()
        container = try? PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
        nodeRepository = NodeRepository(context: context)
        blockRepository = BlockRepository(context: context)
        queryService = NodeQueryService()
        mutationService = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: queryService
        )
    }

    // MARK: - End-to-End Tests

    /// 测试：创建首个节点后可从 repository 取出
    func testCreateFirstNodeAndReload() async throws {
        let newNode = try await mutationService.insertFirst(in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].id, newNode.id)
    }

    /// 测试：创建节点后自动创建的 Block 可从 repository 取出
    func testCreateNodeAlsoCreatesBlock() async throws {
        let newNode = try await mutationService.insertFirst(in: pageID)

        let blocks = try await blockRepository.fetchAll(in: newNode.id)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].type, .text)
    }

    /// 测试：insertAfter 后节点数量正确，sortIndex 有序
    func testInsertAfterPersistsCorrectly() async throws {
        let first = try await mutationService.insertFirst(in: pageID)
        let second = try await mutationService.insertAfter(nodeID: first.id, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        XCTAssertEqual(nodes.count, 2)
        XCTAssertGreaterThan(second.sortIndex, first.sortIndex)
    }

    /// 测试：indent 后节点 parentNodeID 和 depth 持久化正确
    func testIndentPersistsCorrectly() async throws {
        let first = try await mutationService.insertFirst(in: pageID)
        let second = try await mutationService.insertAfter(nodeID: first.id, in: pageID)

        try await mutationService.indent(nodeID: second.id, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let updatedSecond = nodes.first { $0.id == second.id }
        XCTAssertEqual(updatedSecond?.parentNodeID, first.id)
        XCTAssertEqual(updatedSecond?.depth, 1)
    }

    /// 测试：delete 后节点及其 Block 从 repository 中移除
    func testDeleteNodePersistsCorrectly() async throws {
        let node = try await mutationService.insertFirst(in: pageID)

        try await mutationService.delete(nodeID: node.id, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let blocks = try await blockRepository.fetchAll(in: node.id)
        XCTAssertTrue(nodes.isEmpty)
        XCTAssertTrue(blocks.isEmpty)
    }

    /// 测试：buildTree 从持久化数据重建树结构正确
    func testBuildTreeFromPersistedData() async throws {
        let root = try await mutationService.insertFirst(in: pageID)
        let child = try await mutationService.insertAfter(nodeID: root.id, in: pageID)
        try await mutationService.indent(nodeID: child.id, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let blocks = try await blockRepository.fetchAll(in: root.id)
        let allBlocks = try await {
            var all: [Block] = []
            for node in nodes {
                let bs = try await blockRepository.fetchAll(in: node.id)
                all.append(contentsOf: bs)
            }
            return all
        }()

        let tree = queryService.buildTree(nodes: nodes, blocks: allBlocks)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].children.count, 1)
        _ = blocks
    }

    /// 测试：toggleCollapse 后折叠状态持久化，visibleNodes 正确过滤子节点
    func testToggleCollapsePersistsAndFiltersVisibleNodes() async throws {
        let root = try await mutationService.insertFirst(in: pageID)
        let child = try await mutationService.insertAfter(nodeID: root.id, in: pageID)
        try await mutationService.indent(nodeID: child.id, in: pageID)

        try await mutationService.toggleCollapse(nodeID: root.id)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let allBlocks = try await {
            var all: [Block] = []
            for node in nodes {
                let bs = try await blockRepository.fetchAll(in: node.id)
                all.append(contentsOf: bs)
            }
            return all
        }()

        let tree = queryService.buildTree(nodes: nodes, blocks: allBlocks)
        let visible = queryService.visibleNodes(from: tree)
        XCTAssertEqual(visible.count, 1, "折叠后只有根节点可见")
    }
}
