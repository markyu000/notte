//
//  NodeEditorEngine.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import Foundation
import Combine

/// Node 编辑器的核心调度层。
/// 接收 NodeCommand / BlockCommand，路由到对应 Service 执行，
/// 执行完成后重新加载 Node 树并通知 ViewModel 更新。
@MainActor
class NodeEditorEngine: ObservableObject {

    let pageID: UUID
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    let mutationService: NodeMutationService
    let queryService: NodeQueryService
    let blockService: BlockEditingService

    @Published var editorNodes: [EditorNode] = []
    @Published var error: AppError?

    init(
        pageID: UUID,
        nodeRepository: NodeRepositoryProtocol,
        blockRepository: BlockRepositoryProtocol
    ) {
        self.pageID = pageID
        self.nodeRepository = nodeRepository
        self.blockRepository = blockRepository
        self.queryService = NodeQueryService()
        self.mutationService = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
        self.blockService = BlockEditingService(blockRepository: blockRepository)
    }

    // MARK: - 加载

    func loadNodes() async {
        do {
            let nodes = try await nodeRepository.fetchAll(in: pageID)
            var allBlocks: [Block] = []
            for node in nodes {
                let blocks = try await blockRepository.fetchAll(in: node.id)
                allBlocks.append(contentsOf: blocks)
            }
            let roots = queryService.buildTree(nodes: nodes, blocks: allBlocks)
            editorNodes = queryService.visibleNodes(from: roots)
        } catch {
            self.error = .repositoryError(error as? RepositoryError ?? RepositoryError.saveFailed(error))
        }
    }

    // MARK: - Node 命令分发

    func dispatch(_ command: NodeCommand) {
        Task {
            do {
                switch command {
                case .insertAfter(let nodeID):
                    _ = try await mutationService.insertAfter(nodeID: nodeID, in: pageID)
                case .insertChild(let nodeID):
                    _ = try await mutationService.insertChild(nodeID: nodeID, in: pageID)
                case .delete(let nodeID):
                    try await mutationService.delete(nodeID: nodeID, in: pageID)
                case .moveUp(let nodeID):
                    try await mutationService.moveUp(nodeID: nodeID, in: pageID)
                case .moveDown(let nodeID):
                    try await mutationService.moveDown(nodeID: nodeID, in: pageID)
                case .indent(let nodeID):
                    try await mutationService.indent(nodeID: nodeID, in: pageID)
                case .outdent(let nodeID):
                    try await mutationService.outdent(nodeID: nodeID, in: pageID)
                case .toggleCollapse(let nodeID):
                    try await mutationService.toggleCollapse(nodeID: nodeID)
                case .updateTitle(let nodeID, let title):
                    try await mutationService.updateTitle(nodeID: nodeID, title: title)
                }
                await loadNodes()
            } catch {
                self.error = error as? AppError
            }
        }
    }

    // MARK: - Block 命令分发

    func dispatch(_ command: BlockCommand) {
        Task {
            do {
                switch command {
                case .addBlock(let nodeID, let type):
                    _ = try await blockService.addBlock(nodeID: nodeID, type: type)
                case .deleteBlock(let blockID):
                    try await blockService.deleteBlock(blockID: blockID)
                case .updateContent(let blockID, let content):
                    try await blockService.updateContent(blockID: blockID, content: content)
                case .reorderBlock(let blockID, let newSortIndex):
                    try await blockService.reorderBlock(blockID: blockID, newSortIndex: newSortIndex)
                }
                await loadNodes()
            } catch {
                self.error = error as? AppError
            }
        }
    }
}
