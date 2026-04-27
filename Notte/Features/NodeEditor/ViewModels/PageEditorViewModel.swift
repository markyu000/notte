//
//  PageEditorViewModel.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PageEditorViewModel: ObservableObject {

    let pageID: UUID
    let pageTitle: String

    @Published var visibleNodes: [EditorNode] = []
    @Published var focusedNodeID: UUID?
    @Published var pendingFocusNodeID: UUID?
    @Published var error: AppError?
    private let logger = ConsoleLogger()

    private let engine: NodeEditorEngine
    let persistenceCoordinator: NodePersistenceCoordinator

    init(
        pageID: UUID,
        pageTitle: String,
        nodeRepository: NodeRepositoryProtocol,
        blockRepository: BlockRepositoryProtocol
    ) {
        self.pageID = pageID
        self.pageTitle = pageTitle
        let engine = NodeEditorEngine(
            pageID: pageID,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
        self.engine = engine
        self.persistenceCoordinator = NodePersistenceCoordinator(engine: engine)
    }
    
    func createFirstNode() {
        Task {
            do {
                let newNode = try await engine.mutationService.insertFirst(in: pageID)
                logger.debug("首个节点已创建，nodeID：\(newNode.id)", function: #function)
                await engine.loadNodes()
                visibleNodes = engine.editorNodes
            } catch {
                self.error = error as? AppError
            }
        }
    }

    // MARK: - 加载

    func loadPage() async {
        logger.debug("loadPage 已调用，pageID: \(pageID)", function: #function)
        await engine.loadNodes()
        logger.debug("visibleNodes count: \(engine.editorNodes.count)", function: #function)
        visibleNodes = engine.editorNodes
    }

    // MARK: - 命令转发

    func send(_ command: NodeCommand) {
        if case .delete(let nodeID) = command,
           let idx = visibleNodes.firstIndex(where: { $0.id == nodeID }),
           idx > 0 {
            pendingFocusNodeID = visibleNodes[idx - 1].id
        }
        Task {
            await engine.dispatch(command)
            visibleNodes = engine.editorNodes
            error = engine.error
        }
    }

    func send(_ command: BlockCommand) {
        Task {
            await engine.dispatch(command)
            visibleNodes = engine.editorNodes
            error = engine.error
        }
    }

    // MARK: - 内容输入（走 debounce）

    func onTitleChanged(nodeID: UUID, title: String) {
        // 立即更新内存，保持 UI 响应流畅
        if let idx = visibleNodes.firstIndex(where: { $0.id == nodeID }) {
            visibleNodes[idx].title = title
        }
        persistenceCoordinator.scheduleTitleUpdate(nodeID: nodeID, title: title)
    }

    func onContentChanged(blockID: UUID, content: String) {
        for i in visibleNodes.indices {
            if let j = visibleNodes[i].blocks.firstIndex(where: { $0.id == blockID }) {
                visibleNodes[i].blocks[j].content = content
            }
        }
        persistenceCoordinator.scheduleContentUpdate(blockID: blockID, content: content)
    }

    // MARK: - 退出时强制保存

    func onDisappear() {
        Task {
            await persistenceCoordinator.flush()
        }
    }
}
