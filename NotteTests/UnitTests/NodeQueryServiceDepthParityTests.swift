import XCTest
@testable import Notte

/// 临时测试：验证 buildTree 重算出的 depth 与旧持久值 Node.depth 完全等价。
/// 仅在 depth 去持久化重构的并存期存在（Node.depth 仍保留），
/// 删除 Node.depth 字段时必须一并删除本文件，见 NotteDepth重构实施方案.md §3.3、§6.1、§7 步骤 4。
final class NodeQueryServiceDepthParityTests: XCTestCase {

    var queryService: NodeQueryService!
    let pageID = UUID()

    override func setUp() {
        super.setUp()
        queryService = NodeQueryService()
    }

    // MARK: - Helpers

    /// 自洽构造 fixture Node：depth 由调用方手工指定（旧持久值语义），
    /// 不读取真实 SwiftData store，避免历史脏数据污染归因。
    private func makeNode(
        id: UUID = UUID(),
        parentNodeID: UUID? = nil,
        depth: Int,
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

    /// 递归比对每个 EditorNode 的重算 depth 与传入的旧持久值字典
    private func assertDepthParity(
        _ editorNodes: [EditorNode],
        expected: [UUID: Int],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for node in editorNodes {
            XCTAssertEqual(
                node.depth,
                expected[node.id],
                "节点 \(node.id) 重算 depth 与旧持久值不一致",
                file: file,
                line: line
            )
            assertDepthParity(node.children, expected: expected, file: file, line: line)
        }
    }

    // MARK: - Tests

    /// 单个根节点：depth 均为 0
    func testParityWithSingleRoot() throws {
        let root = makeNode(depth: 0, sortIndex: 1000)

        let tree = try queryService.buildTree(nodes: [root], blocks: [])

        assertDepthParity(tree, expected: [root.id: root.depth])
    }

    /// 多个根节点：depth 均为 0，互不影响
    func testParityWithMultipleRoots() throws {
        let root1 = makeNode(depth: 0, sortIndex: 1000)
        let root2 = makeNode(depth: 0, sortIndex: 2000)

        let tree = try queryService.buildTree(nodes: [root1, root2], blocks: [])

        assertDepthParity(tree, expected: [root1.id: root1.depth, root2.id: root2.depth])
    }

    /// 三级嵌套：0/1/2，覆盖 buildTree 递归重算的主路径
    func testParityWithThreeLevels() throws {
        let root = makeNode(depth: 0, sortIndex: 1000)
        let child = makeNode(parentNodeID: root.id, depth: 1, sortIndex: 1500)
        let grandchild = makeNode(parentNodeID: child.id, depth: 2, sortIndex: 1750)

        let tree = try queryService.buildTree(nodes: [root, child, grandchild], blocks: [])

        assertDepthParity(tree, expected: [
            root.id: root.depth,
            child.id: child.depth,
            grandchild.id: grandchild.depth,
        ])
    }

    /// maxDepth 边界：depth 0-4 全部合法层级（NodeHierarchyPolicy.maxDepth = 4）
    func testParityAtMaxDepthBoundary() throws {
        let n0 = makeNode(depth: 0, sortIndex: 1000)
        let n1 = makeNode(parentNodeID: n0.id, depth: 1, sortIndex: 1000)
        let n2 = makeNode(parentNodeID: n1.id, depth: 2, sortIndex: 1000)
        let n3 = makeNode(parentNodeID: n2.id, depth: 3, sortIndex: 1000)
        let n4 = makeNode(parentNodeID: n3.id, depth: 4, sortIndex: 1000)
        let nodes = [n0, n1, n2, n3, n4]

        let tree = try queryService.buildTree(nodes: nodes, blocks: [])

        assertDepthParity(tree, expected: Dictionary(
            uniqueKeysWithValues: nodes.map { ($0.id, $0.depth) }
        ))
    }

    /// 多分支子树：兄弟节点各自的子树深度互不干扰
    func testParityWithMultipleBranches() throws {
        let root = makeNode(depth: 0, sortIndex: 1000)
        let branchA = makeNode(parentNodeID: root.id, depth: 1, sortIndex: 1000)
        let branchALeaf = makeNode(parentNodeID: branchA.id, depth: 2, sortIndex: 1000)
        let branchB = makeNode(parentNodeID: root.id, depth: 1, sortIndex: 2000)
        let nodes = [root, branchA, branchALeaf, branchB]

        let tree = try queryService.buildTree(nodes: nodes, blocks: [])

        assertDepthParity(tree, expected: Dictionary(
            uniqueKeysWithValues: nodes.map { ($0.id, $0.depth) }
        ))
    }
}
