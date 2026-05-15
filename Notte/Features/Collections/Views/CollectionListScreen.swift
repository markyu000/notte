//
//  CollectionListScreen.swift
//  Notte
//
//  Created by yuzheyuan on 2026/4/1.
//

import SwiftUI
import SwiftData

struct CollectionListScreen: View {
    @StateObject private var viewModel: CollectionListViewModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @State private var editMode: EditMode = .inactive
    @State private var collectionToDelete: Collection?
    @State private var isShowingSettings = false

    let pendingAction: RootView.PostOnboardingAction?
    let onActionConsumed: () -> Void

    init(
        repository: CollectionRepositoryProtocol,
        pageRepository: PageRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        pendingAction: RootView.PostOnboardingAction? = nil,
        onActionConsumed: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: CollectionListViewModel(
                repository: repository,
                pageRepository: pageRepository,
                nodeRepository: nodeRepository
            )
        )
        self.pendingAction = pendingAction
        self.onActionConsumed = onActionConsumed
    }

    var body: some View {
        NavigationStack {
            contentView
                .overlay(alignment: .bottomTrailing) {
                    addButton
                }
                .navigationTitle("Notte")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(ColorTokens.accent)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .tint(ColorTokens.accent)
                        .disabled(viewModel.collections.isEmpty)
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $viewModel.isShowingCreateSheet) {
                CollectionCreateSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(
                isPresented: Binding(
                    get: { viewModel.renamingCollectionID != nil},
                    set: { if !$0 { viewModel.renamingCollectionID = nil } }
                )
            ) {
                CollectionRenameSheet(viewModel: viewModel)
            }
            .alert("出错了", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            ), presenting: viewModel.error) { _ in
                Button("好", role: .cancel) { viewModel.error = nil }
            } message: { error in
                Text(error.errorDescription ?? "未知错误")
            }
            .alert("确认删除", isPresented: Binding(
                get: { collectionToDelete != nil },
                set: { if !$0 { collectionToDelete = nil } }
            ), presenting: collectionToDelete) { collection in
                Button("取消", role: .cancel) {
                    collectionToDelete = nil
                }
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deleteCollection(id: collection.id)
                        collectionToDelete = nil
                    }
                }
            } message: { collection in
                Text("确定要删除「\(collection.title)」吗？此操作无法撤销。")
            }
            .task {
                await viewModel.loadCollections()
                switch pendingAction {
                case .createFirst:
                    viewModel.handlePendingCreateFirst()
                case .importSamples:
                    await viewModel.importSampleData(using: dependencyContainer.makeExampleDataFactory())
                case nil:
                    break
                }
                onActionConsumed()
            }
        }
    }

    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.collections.isEmpty {
                CollectionEmptyState {
                    viewModel.isShowingCreateSheet = true
                }
            } else {
                collectionList
            }
        }
    }

    private var addButton: some View {
        Button {
            viewModel.isShowingCreateSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .frame(width: 56, height: 56)
                .foregroundStyle(Color.black)
                .contentShape(Rectangle())
        }
        .buttonStyle(.glassProminent)
        .tint(ColorTokens.accent)
        .buttonBorderShape(.circle)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.trailing, SpacingTokens.md)
        .padding(.bottom, SpacingTokens.lg)
    }

    private var collectionList: some View {
        List {
            ForEach(Array(viewModel.collections.enumerated()), id: \.element.id) { index, collection in
                VStack(spacing: 0) {
                    CollectionCard(collection: collection)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard editMode == .inactive else { return }
                            router
                                .navigate(
                                    to: .pageList(collectionID: collection.id, collectionTitle: collection.title)
                                )
                        }
                        .contextMenu {
                            CollectionContextMenu(
                                collection: collection,
                                onRename: {
                                    viewModel.renamingCollectionID = collection.id
                                    viewModel.renameTitle = collection.title
                                },
                                onPin: {
                                    Task {
                                        await viewModel
                                            .pinCollection(id: collection.id)
                                    }
                                },
                                onDelete: {
                                    collectionToDelete = collection
                                }
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                collectionToDelete = collection
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            Button {
                                viewModel.renamingCollectionID = collection.id
                                viewModel.renameTitle = collection.title
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }
                            .tint(ColorTokens.accent)
                        }
                    
                    // 在最后一个 pinned collection 后添加分割线
                    if isLastPinnedCollection(at: index) {
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: SpacingTokens.md)
                            
                            Rectangle()
                                .fill(ColorTokens.separator)
                                .frame(height: 0.5)
                                .padding(.horizontal, SpacingTokens.md)
                            
                            Spacer()
                                .frame(height: SpacingTokens.sm)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove { from, to in
                guard let sourceIndex = from.first else { return }
                let movingID = viewModel.collections[sourceIndex].id
                let targetID: UUID? = to > 0 ? viewModel.collections[min(to - 1, viewModel.collections.count - 1)].id : nil
                Task {
                    await viewModel
                        .reorderCollection(
                            moving: movingID,
                            after: targetID
                        )
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(-30)
        .background(ColorTokens.backgroundPrimary)
    }
    
    /// 判断指定索引的 collection 是否是最后一个 pinned collection
    private func isLastPinnedCollection(at index: Int) -> Bool {
        guard index < viewModel.collections.count else { return false }
        let collection = viewModel.collections[index]
        
        // 当前 collection 必须是 pinned
        guard collection.isPinned else { return false }
        
        // 检查后面是否有非 pinned 的 collection
        let hasUnpinnedAfter = viewModel.collections
            .dropFirst(index + 1)
            .contains { !$0.isPinned }
        
        return hasUnpinnedAfter
    }
}

#Preview {
    let container = try! PersistenceController.makeContainer(inMemory: true)
    let context = ModelContext(container)
    let repo = try! CollectionRepository(context: context)
    let pageRepo = PageRepository(context: context)
    let nodeRepo = NodeRepository(context: context)
    let dependencyContainer = DependencyContainer(modelContainer: container)

    CollectionListScreen(
        repository: repo,
        pageRepository: pageRepo,
        nodeRepository: nodeRepo
    )
    .task {
        let createUsecase = CreateCollectionUseCase(repository: repo)
        try! await createUsecase.execute(title: "实例1")
        try! await createUsecase.execute(title: "实例2")
    }
    .environmentObject(AppRouter())
    .environmentObject(dependencyContainer)
}
