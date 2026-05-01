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

    /// 测试：单次 scheduleTitleUpdate 在 debounce 后写入 Repository
    func testScheduleTitleUpdatePersistsAfterDebounce() async throws {
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
        try await Task.sleep(for: .milliseconds(600))

        let updated = try await nodeRepository.fetch(by: nodeID)
        XCTAssertEqual(updated?.title, "new")
    }

    /// 测试：高频 scheduleTitleUpdate 只会在最后一次调用 debounce 后写入一次
    func testRapidUpdatesAreCoalesced() async throws {
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
        try await Task.sleep(for: .milliseconds(600))

        let updated = try await nodeRepository.fetch(by: nodeID)
        XCTAssertEqual(updated?.title, "abc")
        XCTAssertEqual(nodeRepository.updateCallCount, 1)
    }

    /// 测试：flush 立即写入未 debounce 完的内容
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
    }

    /// 测试：空队列时 flush 不会调用 Repository
    func testFlushOnEmptyQueueIsNoop() async {
        await coordinator.flush()
        XCTAssertEqual(nodeRepository.updateCallCount, 0)
    }
}
