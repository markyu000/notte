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
import UIKit

@MainActor
class PageEditorViewModel: ObservableObject {

    let pageID: UUID
    let pageTitle: String

    @Published var visibleNodes: [EditorNode] = []
    @Published var nodeAnimationDelays: [UUID: Double] = [:]
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
        self.willResignActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [self] in self.onDisappear() }
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

            // 折叠前预设延迟：让子节点从下到上依次消失
            if case .toggleCollapse(let nodeID) = command,
               visibleNodes.first(where: { $0.id == nodeID })?.isCollapsed == false {
                let descendants = visibleDescendants(of: nodeID)
                var delays: [UUID: Double] = [:]
                for (i, desc) in descendants.reversed().enumerated() {
                    delays[desc.id] = Double(i) * 0.06
                }
                nodeAnimationDelays = delays
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
            visibleNodes = engine.editorNodes
            error = engine.error
            if error == nil, visibleNodes != previousNodes {
                persistenceCoordinator.markStructuralChange()
            }

            // 展开后设置延迟：让子节点从上到下依次出现
            if case .toggleCollapse = command {
                let appearing = visibleNodes.filter { !previousIDs.contains($0.id) }
                if !appearing.isEmpty {
                    var delays = nodeAnimationDelays
                    for (i, node) in appearing.enumerated() {
                        delays[node.id] = Double(i) * 0.06
                    }
                    nodeAnimationDelays = delays
                }
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
        focusedNodeID = nodeID
        pendingFocusNodeID = nil
    }

    func saveChanges() {
        focusedNodeID = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        Task {
            await persistenceCoordinator.flush()
            error = engine.error
        }
    }

    // MARK: - 退出时强制保存

    func onDisappear() {
        Task {
            await persistenceCoordinator.flush()
            error = engine.error
        }
    }

    deinit {
        if let willResignActiveObserver {
            NotificationCenter.default.removeObserver(willResignActiveObserver)
        }
    }
}
