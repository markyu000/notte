import XCTest
@testable import Notte

@MainActor
final class NodePersistenceCoordinatorTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var engine: NodeEditorEngine!
    var coordinator: NodePersistenceCoordinator!

    let pageID = UUID()

    override func setUp() {
        super.setUp()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        engine = NodeEditorEngine(
            pageID: pageID,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
        coordinator = NodePersistenceCoordinator(engine: engine)
    }

    /// 测试：scheduleTitleUpdate 只标记未保存，不会自动写入 Repository
    func testScheduleTitleUpdateDoesNotPersistWithoutFlush() async throws {
        let nodeID = UUID()
        let node = Node(
            id: nodeID,
            pageID: pageID,
            parentNodeID: nil,
            title: "old",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        nodeRepository.storedNodes = [node]

        coordinator.scheduleTitleUpdate(nodeID: nodeID, title: "new")

        let updated = try await nodeRepository.fetch(by: nodeID)
        XCTAssertEqual(updated?.title, "old")
        XCTAssertEqual(coordinator.saveState, .unsaved)
    }

    /// 测试：高频 scheduleTitleUpdate 会保留最后一次未保存内容，直到 flush 时再写入
    func testRapidUpdatesAreCoalescedUntilFlush() async throws {
        let nodeID = UUID()
        let node = Node(
            id: nodeID,
            pageID: pageID,
            parentNodeID: nil,
            title: "",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        nodeRepository.storedNodes = [node]

        coordinator.scheduleTitleUpdate(nodeID: nodeID, title: "a")
        coordinator.scheduleTitleUpdate(nodeID: nodeID, title: "ab")
        coordinator.scheduleTitleUpdate(nodeID: nodeID, title: "abc")
        await coordinator.flush()

        let updated = try await nodeRepository.fetch(by: nodeID)
        XCTAssertEqual(updated?.title, "abc")
        XCTAssertEqual(nodeRepository.updateCallCount, 1)
    }

    /// 测试：flush 立即写入待保存内容
    func testFlushPersistsImmediately() async throws {
        let nodeID = UUID()
        let node = Node(
            id: nodeID,
            pageID: pageID,
            parentNodeID: nil,
            title: "",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        nodeRepository.storedNodes = [node]

        coordinator.scheduleTitleUpdate(nodeID: nodeID, title: "flushed")
        await coordinator.flush()

        let updated = try await nodeRepository.fetch(by: nodeID)
        XCTAssertEqual(updated?.title, "flushed")
        XCTAssertEqual(coordinator.saveState, .saved)
    }

    /// 测试：空队列时 flush 不会调用 Repository
    func testFlushOnEmptyQueueIsNoop() async {
        await coordinator.flush()
        XCTAssertEqual(nodeRepository.updateCallCount, 0)
    }
}
