//
//  PageEditorViewModel.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
class PageEditorViewModel: ObservableObject {

    let pageID: UUID
    let pageTitle: String

    @Published var visibleNodes: [EditorNode] = []
    @Published var isCollapsingAnimation: Bool = false
    @Published var collapsingParentIndex: Int = 0
    @Published var focusedNodeID: UUID?
    @Published var pendingFocusNodeID: UUID?
    @Published var error: AppError?
    private let logger = ConsoleLogger()

    private let engine: NodeEditorEngine
    let persistenceCoordinator: NodePersistenceCoordinator
    private var willResignActiveObserver: NSObjectProtocol?

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

        let coordinator = persistenceCoordinator
        willResignActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await coordinator.flushNow()
            }
        }
    }

    deinit {
        if let willResignActiveObserver {
            NotificationCenter.default.removeObserver(willResignActiveObserver)
        }
    }

    func createTopLevelNode() {
        Task {
            do {
                let newNode = try await engine.mutationService.insertTopLevel(in: pageID)
                logger.debug("顶级节点已创建，nodeID：\(newNode.id)", function: #function)
                await engine.loadNodes()
                visibleNodes = engine.editorNodes
                pendingFocusNodeID = newNode.id
                persistenceCoordinator.markStructuralChange()
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
        if case .delete(let nodeID) = command {
            pendingFocusNodeID = previousVisibleNodeID(before: nodeID)
            if focusedNodeID == nodeID {
                focusedNodeID = nil
            }
        }
        Task {
            let previousNodes = visibleNodes

            // toggleCollapse 单独处理：每个子节点独占一段动画，严格顺序
            if case .toggleCollapse(let nodeID) = command {
                let isCollapsed = visibleNodes.first(where: { $0.id == nodeID })?.isCollapsed ?? false
                if !isCollapsed {
                    await collapseSequentially(nodeID: nodeID)
                } else {
                    await expandSequentially(nodeID: nodeID)
                }
                error = engine.error
                if error == nil, visibleNodes != previousNodes {
                    persistenceCoordinator.markStructuralChange()
                }
                return
            }

            // 结构性命令前先 flush，防止 pending title 与新状态竞争
            switch command {
            case .insertAfter, .insertChild, .delete, .indent, .outdent, .moveUp, .moveDown:
                await persistenceCoordinator.flush()
            default:
                break
            }

            let previousIDs = Set(visibleNodes.map(\.id))
            await engine.dispatch(command)
            withAnimation(.spring(duration: 0.35)) {
                visibleNodes = engine.editorNodes
            }
            error = engine.error
            if error == nil, visibleNodes != previousNodes {
                persistenceCoordinator.markStructuralChange()
            }

            switch command {
            case .insertAfter, .insertChild:
                if let new = visibleNodes.first(where: { !previousIDs.contains($0.id) }) {
                    pendingFocusNodeID = new.id
                }
            case .delete:
                if let pendingFocusNodeID,
                   visibleNodes.contains(where: { $0.id == pendingFocusNodeID }) {
                    self.pendingFocusNodeID = pendingFocusNodeID
                } else {
                    pendingFocusNodeID = nil
                }
            default:
                break
            }
        }
    }

    // MARK: - 折叠/展开

    private func collapseSequentially(nodeID: UUID) async {
        isCollapsingAnimation = true
        collapsingParentIndex = visibleNodes.firstIndex(where: { $0.id == nodeID }) ?? 0
        await engine.dispatch(.toggleCollapse(nodeID: nodeID))
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            visibleNodes = engine.editorNodes
        }
    }

    private func expandSequentially(nodeID: UUID) async {
        isCollapsingAnimation = false
        collapsingParentIndex = visibleNodes.firstIndex(where: { $0.id == nodeID }) ?? 0
        await engine.dispatch(.toggleCollapse(nodeID: nodeID))
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            visibleNodes = engine.editorNodes
        }
    }

    private func visibleDescendants(of nodeID: UUID) -> [EditorNode] {
        guard let parentIdx = visibleNodes.firstIndex(where: { $0.id == nodeID }) else { return [] }
        let parentDepth = visibleNodes[parentIdx].depth
        var result: [EditorNode] = []
        var idx = parentIdx + 1
        while idx < visibleNodes.count && visibleNodes[idx].depth > parentDepth {
            result.append(visibleNodes[idx])
            idx += 1
        }
        return result
    }

    func send(_ command: BlockCommand) {
        Task {
            let previousNodes = visibleNodes
            await engine.dispatch(command)
            visibleNodes = engine.editorNodes
            error = engine.error
            if error == nil, visibleNodes != previousNodes {
                persistenceCoordinator.markStructuralChange()
            }
        }
    }

    // MARK: - 内容输入（标记未保存）

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

    private func previousVisibleNodeID(before nodeID: UUID) -> UUID? {
        guard let idx = visibleNodes.firstIndex(where: { $0.id == nodeID }),
              idx > 0 else {
            return nil
        }
        return visibleNodes[idx - 1].id
    }

    func didFocusNode(_ nodeID: UUID) {
        guard focusedNodeID != nodeID || pendingFocusNodeID != nil else { return }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.82)) {
            focusedNodeID = nodeID
        }
        pendingFocusNodeID = nil
    }

    func saveChanges() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.82)) {
            focusedNodeID = nil
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        Task {
            await persistenceCoordinator.flush()
            error = engine.error
        }
    }
    
    // MARK: - Node层级限制
    
    var canAddChildToFocusedNode: Bool {
        guard let focusedNodeID,
              let node = visibleNodes.first(where: { $0.id == focusedNodeID })
        else { return false }
        return NodeHierarchyPolicy.canAddChild(parentDepth: node.depth)
    }

    // MARK: - Node聚焦判断

    var hasFocusedNode: Bool { focusedNodeID != nil }

    // MARK: - 退出时强制保存

    func onDisappear() {
        Task {
            await persistenceCoordinator.flushNow()
            error = engine.error
        }
    }
    
    // MARK: - 包装Coodinator flushNow函数
    func flushNow() async {
        await persistenceCoordinator.flushNow()
        error = engine.error
    }
}
