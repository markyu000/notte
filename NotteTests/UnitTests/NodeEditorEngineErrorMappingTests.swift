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
        depth: Int,
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

    /// 父节点 depth == maxDepth(4)，执行 insertChild 命令：
    /// NodeMutationService 会抛裸 NodeError.maxDepthExceeded，
    /// 经 NodeEditorEngine.dispatch 的 AppError.wrap 应落到 engine.error 为 .nodeError。
    func test_dispatchInsertChild_atMaxDepth_surfacesNodeErrorToUI() async {
        let maxDepthParent = makeNode(depth: NodeHierarchyPolicy.maxDepth, sortIndex: 1000)
        nodeRepository.storedNodes = [maxDepthParent]

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
        let parent = makeNode(depth: 0, sortIndex: 1000)
        nodeRepository.storedNodes = [parent]

        await engine.dispatch(.insertChild(nodeID: parent.id))

        XCTAssertNil(engine.error, "未达最大层级时不应产生错误")
        XCTAssertEqual(nodeRepository.storedNodes.count, 2, "应成功插入子节点")
    }
}
