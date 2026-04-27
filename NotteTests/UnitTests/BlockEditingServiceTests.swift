import XCTest
@testable import Notte

@MainActor
final class BlockEditingServiceTests: XCTestCase {

    var blockRepository: MockBlockRepository!
    var blockService: BlockEditingService!

    let nodeID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    override func setUp() {
        super.setUp()
        blockRepository = MockBlockRepository()
        blockService = BlockEditingService(blockRepository: blockRepository)
    }

    private func makeBlock(
        id: UUID = UUID(),
        nodeID: UUID? = nil,
        content: String = "",
        sortIndex: Double = 1000
    ) -> Block {
        Block(
            id: id,
            nodeID: nodeID ?? self.nodeID,
            type: .text,
            content: content,
            sortIndex: sortIndex,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - addBlock Tests

    /// 测试：添加 Block 后存入 repository
    func testAddBlockCreatesBlock() async throws {
        let block = try await blockService.addBlock(nodeID: nodeID, type: .text)

        XCTAssertEqual(blockRepository.storedBlocks.count, 1)
        XCTAssertEqual(block.nodeID, nodeID)
        XCTAssertEqual(block.type, .text)
        XCTAssertEqual(block.content, "")
    }

    /// 测试：首个 Block 使用初始 sortIndex
    func testAddFirstBlockUsesInitialSortIndex() async throws {
        let block = try await blockService.addBlock(nodeID: nodeID, type: .text)

        XCTAssertEqual(block.sortIndex, SortIndexPolicy.initialIndex())
    }

    /// 测试：追加 Block 时 sortIndex 大于已有最大值
    func testAddBlockSortIndexAfterExisting() async throws {
        blockRepository.storedBlocks = [makeBlock(sortIndex: 1000)]

        let newBlock = try await blockService.addBlock(nodeID: nodeID, type: .text)

        XCTAssertGreaterThan(newBlock.sortIndex, 1000)
    }

    // MARK: - deleteBlock Tests

    /// 测试：删除 Block 后从 repository 移除
    func testDeleteBlockRemovesFromRepository() async throws {
        let block = makeBlock()
        blockRepository.storedBlocks = [block]

        try await blockService.deleteBlock(blockID: block.id)

        XCTAssertTrue(blockRepository.storedBlocks.isEmpty)
    }

    /// 测试：删除不存在的 Block 时抛出错误
    func testDeleteBlockThrowsWhenNotFound() async {
        do {
            try await blockService.deleteBlock(blockID: UUID())
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    /// 测试：只删除指定 Block，不影响其他 Block
    func testDeleteBlockDoesNotAffectOthers() async throws {
        let block1 = makeBlock(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, sortIndex: 1000)
        let block2 = makeBlock(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, sortIndex: 2000)
        blockRepository.storedBlocks = [block1, block2]

        try await blockService.deleteBlock(blockID: block1.id)

        XCTAssertEqual(blockRepository.storedBlocks.count, 1)
        XCTAssertEqual(blockRepository.storedBlocks[0].id, block2.id)
    }

    // MARK: - updateContent Tests

    /// 测试：更新内容后内容正确写入
    func testUpdateContentSavesNewContent() async throws {
        let block = makeBlock(content: "old content")
        blockRepository.storedBlocks = [block]

        try await blockService.updateContent(blockID: block.id, content: "new content")

        let updated = try await blockRepository.fetch(by: block.id)
        XCTAssertEqual(updated?.content, "new content")
    }

    /// 测试：内容更新为空字符串
    func testUpdateContentWithEmptyString() async throws {
        let block = makeBlock(content: "some content")
        blockRepository.storedBlocks = [block]

        try await blockService.updateContent(blockID: block.id, content: "")

        let updated = try await blockRepository.fetch(by: block.id)
        XCTAssertEqual(updated?.content, "")
    }

    /// 测试：找不到 Block 时抛出错误
    func testUpdateContentThrowsWhenNotFound() async {
        do {
            try await blockService.updateContent(blockID: UUID(), content: "new content")
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
