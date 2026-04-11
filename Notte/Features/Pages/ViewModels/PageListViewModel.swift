//
//  PageListViewModel.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/9.
//

import Combine
import Foundation

@MainActor
class PageListViewModel: ObservableObject {
    let collectionID: UUID
    let collectionTitle: String

    // MARK: - 数据状态
    @Published var pages: [Page] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    // MARK: - 创建弹窗状态
    @Published var isShowingCreateSheet: Bool = false
    @Published var newPageTitle: String = ""

    // MARK: - 重命名状态
    @Published var renamingPageID: UUID?
    @Published var renameTitle: String = ""

    // MARK: - UseCases
    private let fetchUseCase: FetchPagesByCollectionUseCase
    private let createUseCase: CreatePageUseCase
    private let renameUseCase: RenamePageUseCase
    private let deleteUseCase: DeletePageUseCase
    private let duplicateUseCase: DuplicatePageUseCase
    private let reorderUseCase: ReorderPagesUseCase

    init(
        collectionID: UUID,
        collectionTitle: String,
        pageRepository: PageRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol
    ) {
        self.collectionID = collectionID
        self.collectionTitle = collectionTitle
        self.fetchUseCase = FetchPagesByCollectionUseCase(
            repository: pageRepository
        )
        self.createUseCase = CreatePageUseCase(repository: pageRepository)
        self.renameUseCase = RenamePageUseCase(repository: pageRepository)
        self.deleteUseCase = DeletePageUseCase(
            repository: pageRepository,
            nodeRepository: nodeRepository
        )
        self.duplicateUseCase = DuplicatePageUseCase(repository: pageRepository)
        self.reorderUseCase = ReorderPagesUseCase(repository: pageRepository)
    }

    // MARK: - 操作方法
    func loadPages() async {
        isLoading = true
        defer { isLoading = false }
        do {
            pages = try await fetchUseCase.execute(collectionID: collectionID)
        } catch {
            self.error = error as? AppError
        }
    }

    func createPage() async {
        guard !newPageTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        do {
            try await createUseCase.execute(
                title: newPageTitle,
                in: collectionID
            )
            newPageTitle = ""
            isShowingCreateSheet = false
            await loadPages()
        } catch {
            self.error = error as? AppError
        }
    }

    func renamePage(id: UUID) async {
        guard !renameTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        do {
            try await renameUseCase.execute(id: id, newTitle: renameTitle)
            renamingPageID = nil
            await loadPages()
        } catch {
            self.error = error as? AppError
        }
    }

    func deletePage(id: UUID) async {
        do {
            try await deleteUseCase.execute(pageID: id)
            await loadPages()
        } catch {
            self.error = error as? AppError
        }
    }

    func duplicatePage(id: UUID) async {
        do {
            try await duplicateUseCase.execute(pageID: id)
            await loadPages()
        } catch {
            self.error = error as? AppError
        }
    }

    func reorderPage(moving id: UUID, after targetID: UUID?) async {
        do {
            try await reorderUseCase.execute(
                collectionID: collectionID,
                moving: id,
                after: targetID
            )
            await loadPages()
        } catch {
            self.error = error as? AppError
        }
    }
}
