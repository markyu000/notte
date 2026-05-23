//
//  PageEditorView.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI
import SwiftData

struct PageEditorView: View {

    @ObservedObject var viewModel: PageEditorViewModel
    @ObservedObject private var persistenceCoordinator:
        NodePersistenceCoordinator
    @State private var showAddMenu = false

    init(viewModel: PageEditorViewModel) {
        self.viewModel = viewModel
        _persistenceCoordinator = ObservedObject(
            wrappedValue: viewModel.persistenceCoordinator
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.visibleNodes.isEmpty {
                        // 空状态：通过顶部按钮创建第一个顶级节点
                        ColorTokens.backgroundPrimary
                            .frame(maxWidth: .infinity, minHeight: 400)
                            .overlay(
                                Text("点击左上角加号创建顶级节点")
                                    .font(TypographyTokens.body)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            )
                    } else {
                        let nodeCount = viewModel.visibleNodes.count
                        ForEach(Array(viewModel.visibleNodes.enumerated()), id: \.element.id) { index, node in
                            NodeRowView(
                                node: node,
                                isFocused: viewModel.focusedNodeID == node.id
                                    || viewModel.pendingFocusNodeID == node.id,
                                onTitleChanged: { title in
                                    viewModel.onTitleChanged(
                                        nodeID: node.id,
                                        title: title
                                    )
                                },
                                onContentChanged: { blockID, content in
                                    viewModel.onContentChanged(
                                        blockID: blockID,
                                        content: content
                                    )
                                },
                                onCommand: { command in
                                    viewModel.send(command)
                                },
                                onFocused: { id in
                                    viewModel.didFocusNode(id)
                                }
                            )
                            .id(node.id)
                            .transition(.nodeExpand)
                            .transaction(value: viewModel.visibleNodes.map(\.id)) { t in
                                // 用 transaction 直接覆盖动画，避免被父级 withAnimation 覆盖
                                let delay = viewModel.nodeAnimationDelays[node.id] ?? 0
                                t.animation = .spring(duration: 0.35).delay(delay)
                            }
                            // 列表靠前的节点 zIndex 略高，确保折叠时先移动的节点藏到后面
                            .zIndex(Double(100 - node.depth) + Double(nodeCount - index) * 0.01)
                        }

                        ColorTokens.backgroundPrimary
                            .frame(height: 200)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: viewModel.focusedNodeID) { _, newID in
                guard let id = newID else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
        .navigationTitle(viewModel.pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPage()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .alert(
            "错误",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            Button("好") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        handleAddSibling()
                    } label: {
                        Label("添加同级节点", systemImage: "text.append")
                    }
                    .disabled(viewModel.focusedNodeID == nil)

                    Button {
                        handleAddChild()
                    } label: {
                        Label("添加子节点", systemImage: "arrow.turn.down.right")
                    }
                    .disabled(viewModel.focusedNodeID == nil)

                    Button {
                        handleAddRoot()
                    } label: {
                        Label("添加根节点", systemImage: "text.alignleft")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(ColorTokens.textPrimary)
                } primaryAction: {
                    handleSmartAdd()
                }
            }
            if viewModel.focusedNodeID != nil || persistenceCoordinator.hasUnsavedChanges {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ColorTokens.accent)
                    .disabled(persistenceCoordinator.saveState == .saving)
                }
            }
        }
    }

    // MARK: - + 按钮处理

    private func handleSmartAdd() {
        if let focusedID = viewModel.focusedNodeID {
            // 有焦点 → 在当前节点后插入同级
            viewModel.send(.insertAfter(nodeID: focusedID))
        } else {
            // 无焦点 → 创建顶级节点
            viewModel.createTopLevelNode()
        }
    }

    private func handleAddSibling() {
        guard let focusedID = viewModel.focusedNodeID else {
            viewModel.createTopLevelNode()
            return
        }
        viewModel.send(.insertAfter(nodeID: focusedID))
    }

    private func handleAddChild() {
        guard let focusedID = viewModel.focusedNodeID else {
            viewModel.createTopLevelNode()
            return
        }
        viewModel.send(.insertChild(nodeID: focusedID))
    }

    private func handleAddRoot() {
        viewModel.createTopLevelNode()
    }
}

private struct NodeSlideModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content.offset(y: offset).opacity(opacity)
    }
}

// 折叠时从底部向上裁剪，模拟被上方元素擦除的效果
private struct NodeCollapseClipShape: Shape {
    var fraction: CGFloat  // 1 = 完整显示，0 = 完全隐藏（从底部开始消失）
    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: 0, width: rect.width, height: rect.height * fraction))
    }
}

private struct NodeCollapseModifier: ViewModifier {
    let fraction: CGFloat
    func body(content: Content) -> some View {
        content.clipShape(NodeCollapseClipShape(fraction: fraction))
    }
}

private extension AnyTransition {
    // 展开：子节点从父节点下方向下滑入
    // 折叠：子节点被从底部向上裁剪掉（模拟同级节点向上擦除）
    static var nodeExpand: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: NodeSlideModifier(offset: -36, opacity: 0),
                identity: NodeSlideModifier(offset: 0, opacity: 1)
            ),
            removal: .modifier(
                active: NodeCollapseModifier(fraction: 0),
                identity: NodeCollapseModifier(fraction: 1)
            )
        )
    }
}

#Preview {
    let pageID = UUID()
    let container = try! PersistenceController.makeContainer(inMemory: true)
    let context = ModelContext(container)
    let nodeRepo = NodeRepository(context: context)
    let blockRepo = BlockRepository(context: context)
    let viewModel = PageEditorViewModel(
        pageID: pageID,
        pageTitle: "示例页面",
        nodeRepository: nodeRepo,
        blockRepository: blockRepo
    )
    NavigationStack {
        PageEditorView(viewModel: viewModel)
    }
}
