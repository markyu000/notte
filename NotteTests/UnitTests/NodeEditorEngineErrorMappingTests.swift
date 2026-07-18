//
//  NodeEditorEngineErrorMappingTests.swift
//  Notte
//
//  回归 issue「大量 catch 用 as? AppError 静默吞错」：
//  NodeMutationService.insertChild 在父节点已达 maxDepth 时抛裸 NodeError.maxDepthExceeded，
//  原先 NodeEditorEngine 的 `error as? AppError` 把它转成 nil，UI 无反馈。
//  改用 AppError.wrap(error) 后，该错误应能一路冒泡到 engine.error 为 .nodeError。
//

import XCTest
@testable import Notte

@MainActor
final class NodeEditorEngineErrorMappingTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var engine: NodeEditorEngine!

    let pageID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    override func setUp() {
        super.setUp()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        engine = NodeEditorEngine(
            pageID: pageID,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
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

    // MARK: - 核心回归：maxDepth 触发的 NodeError 不再被吞

    /// 搭一条长度为 maxDepth（4）的 parentNodeID 链，链尾节点的真实 depth 由
    /// NodeQueryService.depth(of:in:) 现算得出，等于 4——depth 不再持久化，
    /// 不能靠手工传参伪造，必须真的堆出这条祖先链。
    /// 对链尾节点执行 insertChild：NodeMutationService 会抛裸 NodeError.maxDepthExceeded，
    /// 经 NodeEditorEngine.dispatch 的 AppError.wrap 应落到 engine.error 为 .nodeError。
    func test_dispatchInsertChild_atMaxDepth_surfacesNodeErrorToUI() async {
        var previousID: UUID?
        var maxDepthParent: Node!
        for level in 0...NodeHierarchyPolicy.maxDepth {
            let node = makeNode(parentNodeID: previousID, sortIndex: Double(level) * 1000)
            nodeRepository.storedNodes.append(node)
            previousID = node.id
            maxDepthParent = node
        }

        await engine.dispatch(.insertChild(nodeID: maxDepthParent.id))

        XCTAssertNotNil(engine.error, "已达最大层级时操作被拒，错误不应被静默吞掉")
        guard case .nodeError(let nodeError) = engine.error else {
            XCTFail("应映射为 .nodeError，实际：\(String(describing: engine.error))")
            return
        }
        XCTAssertEqual(nodeError, .maxDepthExceeded)
    }

    // MARK: - 反例：正常层级不报错

    /// 父节点 depth < maxDepth，insertChild 成功，engine.error 应保持为 nil。
    func test_dispatchInsertChild_belowMaxDepth_doesNotSetError() async {
        let parent = makeNode(sortIndex: 1000)
        nodeRepository.storedNodes = [parent]

        await engine.dispatch(.insertChild(nodeID: parent.id))

        XCTAssertNil(engine.error, "未达最大层级时不应产生错误")
        XCTAssertEqual(nodeRepository.storedNodes.count, 2, "应成功插入子节点")
    }
}
