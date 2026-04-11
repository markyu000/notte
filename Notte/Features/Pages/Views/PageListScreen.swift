//
//  PageListScreen.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/10.
//

import SwiftUI
import SwiftData

struct PageListScreen: View {
    @StateObject private var viewModel: PageListViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var editMode: EditMode = .inactive
    @State private var pageToDelete: Page?

    init(
        collectionID: UUID,
        collectionTitle: String,
        pageRepository: PageRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: PageListViewModel(
                collectionID: collectionID,
                collectionTitle: collectionTitle,
                pageRepository: pageRepository,
                nodeRepository: nodeRepository
            )
        )
    }
    
    var body: some View {
        contentView
            .navigationTitle(viewModel.collectionTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $viewModel.isShowingCreateSheet) {
                PageCreateSheet(viewModel: viewModel)
            }
            .sheet(
                isPresented: Binding(
                    get: { viewModel.renamingPageID != nil },
                    set: { if !$0 { viewModel.renamingPageID = nil } }
                )
            ) {
                PageRenameSheet(viewModel: viewModel)
            }
            .modifier(PageDeleteAlertModifier(pageToDelete: $pageToDelete, viewModel: viewModel))
            .modifier(PageErrorAlertModifier(viewModel: viewModel))
            .task {
                await viewModel.loadPages()
            }
    }

    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.pages.isEmpty {
                PageEmptyState {
                    viewModel.isShowingCreateSheet = true
                }
            } else {
                pageList
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.isShowingCreateSheet = true
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(ColorTokens.accent)
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
                .tint(ColorTokens.accent)
                .disabled(viewModel.pages.isEmpty)
        }
    }

    private var pageList: some View {
        List {
            ForEach(viewModel.pages) { page in
                PageRow(page: page)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard editMode == .inactive else { return }
                        router.navigate(to: .nodeEditor(pageID: page.id))
                    }
                    .contextMenu {
                        PageContextMenu(
                            page: page, 
                            onRename: {
                                viewModel.renamingPageID = page.id
                                viewModel.renameTitle = page.title
                            },
                            onDelete: {
                                pageToDelete = page
                            },
                            onDuplicate: {
                                Task { await viewModel.duplicatePage(id: page.id) }
                            }
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pageToDelete = page
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        Button {
                            viewModel.renamingPageID = page.id
                            viewModel.renameTitle = page.title
                        } label: {
                            Label("重命名", systemImage: "pencil")
                        }
                        .tint(ColorTokens.accent)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onMove { from, to in
                guard let sourceIndex = from.first else { return }
                let movingID = viewModel.pages[sourceIndex].id
                let targetID: UUID? = to > 0
                ? viewModel.pages[min(to - 1, viewModel.pages.count - 1)].id
                : nil
                Task {
                    await viewModel.reorderPage(moving: movingID, after: targetID)
                }
            }
        }
        .listStyle(.plain)
        .background(ColorTokens.backgroundPrimary)
    }
    
    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Alert Modifiers

private struct PageDeleteAlertModifier: ViewModifier {
    @Binding var pageToDelete: Page?
    let viewModel: PageListViewModel

    func body(content: Content) -> some View {
        content.alert("确认删除", isPresented: Binding(
            get: { pageToDelete != nil },
            set: { if !$0 { pageToDelete = nil } }
        ), presenting: pageToDelete) { page in
            Button("取消", role: .cancel) {
                pageToDelete = nil
            }
            Button("删除", role: .destructive) {
                Task {
                    await viewModel.deletePage(id: page.id)
                    pageToDelete = nil
                }
            }
        } message: { page in
            Text("删除「\(page.title)」将同时删除其全部内容，此操作无法撤销。")
        }
    }
}

private struct PageErrorAlertModifier: ViewModifier {
    @ObservedObject var viewModel: PageListViewModel

    func body(content: Content) -> some View {
        content.alert("出错了", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        ), presenting: viewModel.error) { _ in
            Button("好", role: .cancel) { viewModel.error = nil }
        } message: { error in
            Text(error.errorDescription ?? "未知错误")
        }
    }
}

#Preview {
    let collectionID = UUID()
    let container = try! PersistenceController.makeContainer(inMemory: true)
    let context = ModelContext(container)
    let pageRepo = PageRepository(context: context)
    let nodeRepo = NodeRepository(context: context)

    NavigationStack {
        PageListScreen(
            collectionID: collectionID,
            collectionTitle: "我的笔记",
            pageRepository: pageRepo,
            nodeRepository: nodeRepo
        )
    }
    .task {
        let createUseCase = CreatePageUseCase(repository: pageRepo)
        for i in 1...3 {
            try! await createUseCase.execute(title: "Page \(i)", in: collectionID)
        }
    }
    .environmentObject(AppRouter())
}
