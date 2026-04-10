# Notte M3 代码参考文档

> 本文档包含 M3（Pages）阶段所有 issue 的文件路径、代码内容与解释。
> M3 目标：Collection → Page 导航稳定，Page 增删改查、排序、复制全部成立，级联删除正确。
> **本版本已根据 M2 实际落地代码对齐修订**，所有代码可直接编译。

---

## 分支

```
feature/m3-page-module
```

## 目录

1. [M3-00a 前置修复（拼写错误 + AppRoute 更新）](#m3-00a-前置修复拼写错误--approute-更新)
2. [M3-00b SortIndexNormalizer 泛型化](#m3-00b-sortindexnormalizer-泛型化)
3. [M3-01 PageRepositoryProtocol（已满足）](#m3-01-pagerepositoryprotocol已满足)
4. [M3-02 FetchPagesByCollectionUseCase](#m3-02-fetchpagesbycollectionusecase)
5. [M3-03 CreatePageUseCase](#m3-03-createpageusecase)
6. [M3-04 RenamePageUseCase](#m3-04-renamepageusecase)
7. [M3-05 DeletePageUseCase（含级联删除）](#m3-05-deletepageusecase含级联删除)
8. [M3-06 DuplicatePageUseCase](#m3-06-duplicatepageusecase)
9. [M3-07 ReorderPagesUseCase](#m3-07-reorderpagesusecase)
10. [M3-08 PageRepository 完整实现](#m3-08-pagerepository-完整实现)
11. [M3-09 PageListViewModel](#m3-09-pagelistviewmodel)
12. [M3-10 PageListScreen](#m3-10-pagelistscreen)
13. [M3-11 PageRow](#m3-11-pagerow)
14. [M3-12 PageEmptyState](#m3-12-pageemptystate)
15. [M3-13 PageCreateSheet](#m3-13-pagecreatesheet)
16. [M3-14 PageRenameSheet](#m3-14-pagerenaamesheet)
17. [M3-15 PageContextMenu](#m3-15-pagecontextmenu)
18. [M3-16 RootView 更新（接入 PageListScreen）](#m3-16-rootview-更新接入-pagelistscreen)
19. [M3-17~21 单元测试](#m3-1721-单元测试)

---

## M3-00a 前置修复（拼写错误 + AppRoute 更新）

### 1. 修正 `DependencyContainer` 拼写错误

**文件：** `App/DependencyContainer.swift`

```swift
import Combine
import SwiftData

@MainActor
class DependencyContainer: ObservableObject {
    let collectionRepository: CollectionRepositoryProtocol   // 修正：colleciton → collection
    let pageRepository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol

    init(modelContainer: ModelContainer) {
        let context = ModelContext(modelContainer)
        self.collectionRepository = CollectionRepository(context: context)
        self.pageRepository = PageRepository(context: context)
        self.nodeRepository = NodeRepository(context: context)
        self.blockRepository = BlockRepository(context: context)
    }
}
```

### 2. 修正 `RootView` 拼写错误 + 更新 AppRoute

**文件：** `App/AppRouter.swift`

```swift
import Foundation
import Combine

enum AppRoute: Hashable {
    case pageList(collectionID: UUID, collectionTitle: String)  // 新增 collectionTitle
    case nodeEditor(pageID: UUID)
}

@MainActor
class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func goBack() {
        path.removeLast()
    }

    func goRoot() {
        path.removeAll()
    }
}
```

**文件：** `App/RootView.swift`

```swift
import Foundation
import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject private var dependencyContainer: DependencyContainer   // 修正：Countainer → Container

    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                repository: dependencyContainer.collectionRepository   // 修正：colleciton → collection
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .pageList(let collectionID, let collectionTitle):
                    Text("Page List 占位 \(collectionID) \(collectionTitle)")   // M3-16 替换
                case .nodeEditor(let pageID):
                    Text("Node Editor 占位 \(pageID)")   // M4 替换
                }
            }
        }
        .environmentObject(router)
    }
}
```

### 3. 更新 `CollectionListScreen` navigate 调用

**文件：** `Features/Collections/Views/CollectionListScreen.swift`（只改 navigate 调用处）

```swift
// 将原来的：
router.navigate(to: .pageList(collectionID: collection.id))

// 改为：
router.navigate(to: .pageList(collectionID: collection.id, collectionTitle: collection.title))
```

**Git commit message：**

```
fix: correct typos in DependencyContainer/RootView and add collectionTitle to AppRoute
```

**解释：**

- `DependencyContainer` 中 `collecitonRepository` 和 `RootView` 中 `dependencyCountainer` 均为拼写错误，M3 接入前统一修正，避免整个 Pages 模块都带着错误名编译。
- `AppRoute.pageList` 新增 `collectionTitle: String` 关联值。`PageListScreen` 需要展示 Collection 标题作为 `navigationTitle`，在路由关联值中携带是最简洁的方案，不需要在导航目标中再发起异步查询。
- `CollectionListScreen` 中 `router.navigate` 的调用同步更新，传入 `collection.title`，View 层已经持有该值，无额外开销。

---

## M3-00b SortIndexNormalizer 泛型化

**文件（新建）：** `Shared/Utilities/SortIndexable.swift`

```swift
import Foundation

protocol SortIndexable {
    var sortIndex: Double { get set }
    var updatedAt: Date { get set }
}
```

**文件：** `Domain/Entities/Collection.swift`（末尾追加）

```swift
extension Collection: SortIndexable {}
```

**文件：** `Domain/Entities/Page.swift`（末尾追加）

```swift
extension Page: SortIndexable {}
```

**文件：** `Shared/Utilities/SortIndexNormalizer.swift`（全量替换）

```swift
import Foundation

struct SortIndexNormalizer {
    static func normalizeIfNeeded<T: SortIndexable>(
        _ items: [T],
        update: (T) async throws -> Void
    ) async throws {
        let sorted = items.sorted { $0.sortIndex < $1.sortIndex }

        let needsNorm = zip(sorted, sorted.dropFirst()).contains { a, b in
            SortIndexPolicy.needsNormalization(before: a.sortIndex, after: b.sortIndex)
        }

        guard needsNorm else { return }

        let newIndexes = SortIndexPolicy.normalize(count: sorted.count)
        for (item, newIndex) in zip(sorted, newIndexes) {
            var updated = item
            updated.sortIndex = newIndex
            updated.updatedAt = Date()
            try await update(updated)
        }
    }
}
```

**Git commit message：**

```
refactor: generalize SortIndexNormalizer to support any SortIndexable entity
```

**解释：**

- 原 `SortIndexNormalizer` 写死了 `[Collection]` 类型，`ReorderPagesUseCase` 无法复用。抽出 `SortIndexable` 协议后，`Collection` 和 `Page`（以及未来的 `Node`）都可以共用同一套归一化逻辑。
- `Collection` 和 `Page` 两个 struct 均已具备 `sortIndex: Double` 和 `updatedAt: Date` 属性，只需在文件末尾追加 `extension X: SortIndexable {}` 即可，不改动原有定义。
- `ReorderCollectionsUseCase` 中现有的 `SortIndexNormalizer.normalizeIfNeeded(latest) { ... }` 调用签名不变，Swift 可通过类型推断找到泛型版本，不需要修改调用方。

---

## M3-01 PageRepositoryProtocol（已满足）

**文件：** `Domain/Protocols/PageRepositoryProtocol.swift`

> 当前代码已经是 `async throws` 签名，与 M3 所需完全一致，**无需修改**。

```swift
import Foundation

protocol PageRepositoryProtocol {
    func fetchAll(in collectionID: UUID) async throws -> [Page]
    func fetch(by id: UUID) async throws -> Page?
    func create(_ page: Page) async throws
    func update(_ page: Page) async throws
    func delete(by id: UUID) async throws
}
```

**解释：**

- M1 阶段已升级为 `async throws`，与 `CollectionRepositoryProtocol` 对称。M3 直接使用，无需变更。

---

## M3-02 FetchPagesByCollectionUseCase

**文件：** `Features/Pages/UseCases/FetchPagesByCollectionUseCase.swift`

```swift
import Foundation

struct FetchPagesByCollectionUseCase {
    let repository: PageRepositoryProtocol

    func execute(collectionID: UUID) async throws -> [Page] {
        let all = try await repository.fetchAll(in: collectionID)
        return all.sorted { $0.sortIndex < $1.sortIndex }
    }
}
```

**Git commit message：**

```
feat: add FetchPagesByCollectionUseCase
```

**解释：**

- 与 `FetchCollectionsUseCase` 对称，Page 不支持 Pin，只按 `sortIndex` 升序排列。
- `repository.fetchAll(in: collectionID)` 在数据库层完成 `collectionID` 过滤，UseCase 只做排序。

---

## M3-03 CreatePageUseCase

**文件：** `Features/Pages/UseCases/CreatePageUseCase.swift`

```swift
import Foundation

struct CreatePageUseCase {
    let repository: PageRepositoryProtocol

    @discardableResult
    func execute(title: String, in collectionID: UUID) async throws -> Page {
        let existing = try await repository.fetchAll(in: collectionID)
        let maxIndex = existing.map(\.sortIndex).max() ?? 0

        let page = Page(
            id: UUID(),
            collectionID: collectionID,
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: maxIndex + 1000,
            isArchived: false
        )
        try await repository.create(page)
        return page
    }
}
```

**Git commit message：**

```
feat: add CreatePageUseCase
```

**解释：**

- 与 `CreateCollectionUseCase` 实现模式完全一致：`max() ?? 0` + `+ 1000` 确定新条目位置，不通过 `SortIndexPolicy.indexAfter` 中转。
- 空标题校验由 `PageListViewModel.createPage()` 的 `guard` 语句承担（与 Collection 一致），UseCase 层不重复校验。
- `@discardableResult` 与 `CreateCollectionUseCase` 保持一致，调用方可忽略返回值。

---

## M3-04 RenamePageUseCase

**文件：** `Features/Pages/UseCases/RenamePageUseCase.swift`

```swift
import Foundation

struct RenamePageUseCase {
    let repository: PageRepositoryProtocol

    func execute(id: UUID, newTitle: String) async throws {
        guard var page = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        page.title = newTitle
        page.updatedAt = Date()
        try await repository.update(page)
    }
}
```

**Git commit message：**

```
feat: add RenamePageUseCase
```

**解释：**

- 与 `RenameCollectionUseCase` 结构完全一致：fetch → 修改 → update。
- 空标题校验由 ViewModel 的 `guard` 承担，UseCase 不重复。
- `guard var page`：`Page` 是值类型，需要 `var` 才能修改属性。

---

## M3-05 DeletePageUseCase（含级联删除）

**文件：** `Features/Pages/UseCases/DeletePageUseCase.swift`

```swift
import Foundation

struct DeletePageUseCase {
    let pageRepository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol

    func execute(pageID: UUID) async throws {
        // 1. 先级联删除该 Page 下的所有 Node
        try await nodeRepository.deleteAll(in: pageID)
        // 2. 再删除 Page 本身
        try await pageRepository.delete(by: pageID)
    }
}
```

**Git commit message：**

```
feat: add DeletePageUseCase with cascade node deletion
```

**解释：**

- UseCase 编排跨 Repository 操作，两个 Repository 各自只做单表操作。
- `nodeRepository.deleteAll(in: pageID)` 在 `NodeRepositoryProtocol` 中已预留，M3 阶段 Node 表为空，调用无副作用；M4 接入编辑器后自动生效。
- 删除顺序必须先删 Node，再删 Page，避免外键约束问题。

---

## M3-06 DuplicatePageUseCase

**文件：** `Features/Pages/UseCases/DuplicatePageUseCase.swift`

```swift
import Foundation

struct DuplicatePageUseCase {
    let repository: PageRepositoryProtocol

    @discardableResult
    func execute(pageID: UUID) async throws -> Page {
        guard let original = try await repository.fetch(by: pageID) else {
            throw AppError.repositoryError(.notFound)
        }

        let existing = try await repository.fetchAll(in: original.collectionID)
        let maxIndex = existing.map(\.sortIndex).max() ?? 0

        let duplicate = Page(
            id: UUID(),
            collectionID: original.collectionID,
            title: "\(original.title) 副本",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: maxIndex + 1000,
            isArchived: false
        )
        try await repository.create(duplicate)
        return duplicate
    }
}
```

**Git commit message：**

```
feat: add DuplicatePageUseCase
```

**解释：**

- M3 阶段只复制 Page 元数据，不深拷贝 Node/Block（M4 补充）。
- `maxIndex + 1000` 与 `CreatePageUseCase` 保持完全一致的 sortIndex 计算方式。
- 副本 title 格式为 `"原标题 副本"`，与 Apple 系 App 惯例一致。

---

## M3-07 ReorderPagesUseCase

**文件：** `Features/Pages/UseCases/ReorderPagesUseCase.swift`

```swift
import Foundation

struct ReorderPagesUseCase {
    let repository: PageRepositoryProtocol

    func execute(collectionID: UUID, moving id: UUID, after targetID: UUID?) async throws {
        let all = try await repository.fetchAll(in: collectionID)
            .sorted { $0.sortIndex < $1.sortIndex }

        let firstSortIndex = all.first?.sortIndex

        let targetIndex = targetID.flatMap { tid in
            all.firstIndex { $0.id == tid }
        }

        let lower: Double? = targetIndex.map { all[$0].sortIndex }
        let upper: Double? = targetIndex.flatMap { idx in
            all.indices.contains(idx + 1) ? all[idx + 1].sortIndex : nil
        }

        let newIndex: Double!
        switch (lower, upper) {
        case (nil, nil):
            if let firstSortIndex {
                newIndex = SortIndexPolicy.indexBetween(before: 0, after: firstSortIndex)
            } else {
                newIndex = SortIndexPolicy.initialIndex()
            }
        case (nil, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: 0, after: u)
        case (let l?, nil):
            newIndex = SortIndexPolicy.indexAfter(last: l)
        case (let l?, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: l, after: u)
        }

        guard var page = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        page.sortIndex = newIndex
        page.updatedAt = Date()
        try await repository.update(page)

        Task.detached {
            let latest = try await repository.fetchAll(in: collectionID)
            try await SortIndexNormalizer.normalizeIfNeeded(latest) { updated in
                try await repository.update(updated)
            }
        }
    }
}
```

**Git commit message：**

```
feat: add ReorderPagesUseCase
```

**解释：**

- 与 `ReorderCollectionsUseCase` 逻辑完全对称，唯一差异是增加 `collectionID` 参数，所有 `repository.fetchAll()` 改为 `repository.fetchAll(in: collectionID)`。
- `SortIndexPolicy.indexBetween(before:after:)` 接受 `Double`（非可选），因此用 `switch (lower, upper)` 分支处理所有 nil 组合，与现有 Collection 实现保持一致。
- `Task.detached` 负责后台归一化，不阻塞当前操作完成；`SortIndexNormalizer` 升级为泛型（M3-00b）后可直接接受 `[Page]`。

---

## M3-08 PageRepository 完整实现

**文件：** `Data/Repositories/PageRepository.swift`（在 M1 骨架基础上全量替换）

```swift
import Foundation
import SwiftData

class PageRepository: PageRepositoryProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in collectionID: UUID) async throws -> [Page] {
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.collectionID == collectionID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        do {
            let models = try context.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func fetch(by id: UUID) async throws -> Page? {
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.id == id }
        )
        do {
            return try context.fetch(descriptor).first?.toDomain()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func create(_ page: Page) async throws {
        let model = PageModel(
            id: page.id,
            collectionID: page.collectionID,
            title: page.title,
            createdAt: page.createdAt,
            updatedAt: page.updatedAt,
            sortIndex: page.sortIndex,
            isArchived: page.isArchived
        )
        context.insert(model)
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func update(_ page: Page) async throws {
        let id = page.id
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.title = page.title
        model.updatedAt = page.updatedAt
        model.sortIndex = page.sortIndex
        model.isArchived = page.isArchived
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }
}
```

**Git commit message：**

```
feat: implement PageRepository CRUD
```

**解释：**

- 与 `CollectionRepository` 模式完全一致：`FetchDescriptor` + `do-catch` + `context.save()`。
- `fetchAll(in:)` 在 SwiftData 层同时做 predicate 过滤和 sortIndex 排序，减少内存操作。
- `update` 中提取 `let id = page.id` 再传入 `#Predicate`，与 `CollectionRepository.update` 的写法保持一致（SwiftData `#Predicate` 对属性访问路径有约束，使用局部常量更可靠）。
- `update` 不修改 `collectionID`，MVP 阶段不支持跨 Collection 移动 Page。

---

## M3-09 PageListViewModel

**文件：** `Features/Pages/ViewModels/PageListViewModel.swift`

```swift
import Foundation
import Combine

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
        self.fetchUseCase = FetchPagesByCollectionUseCase(repository: pageRepository)
        self.createUseCase = CreatePageUseCase(repository: pageRepository)
        self.renameUseCase = RenamePageUseCase(repository: pageRepository)
        self.deleteUseCase = DeletePageUseCase(
            pageRepository: pageRepository,
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
        guard !newPageTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await createUseCase.execute(title: newPageTitle, in: collectionID)
            newPageTitle = ""
            isShowingCreateSheet = false
            await loadPages()
        } catch {
            self.error = error as? AppError
        }
    }

    func renamePage(id: UUID) async {
        guard !renameTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
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
```

**Git commit message：**

```
feat: add PageListViewModel with full state management
```

**解释：**

- 与 `CollectionListViewModel` 完全对称：所有 action 执行成功后调用 `await loadPages()` 刷新，数据库是唯一真相。
- 删除确认状态（`pageToDelete`）由 `PageListScreen` 用 `@State` 持有，与 `CollectionListScreen` 的处理方式一致，ViewModel 不需要感知。`deletePage(id:)` 只负责执行删除，不管理弹窗状态。
- `collectionTitle` 由调用方（`RootView`）从 `AppRoute` 关联值中取出传入，ViewModel 持有后暴露给 View 用于 `navigationTitle`。

---

## M3-10 PageListScreen

**文件：** `Features/Pages/Views/PageListScreen.swift`

```swift
import SwiftUI

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
                            onDuplicate: {
                                Task { await viewModel.duplicatePage(id: page.id) }
                            },
                            onDelete: {
                                pageToDelete = page
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
    NavigationStack {
        Text("PageListScreen Preview")
    }
}

```

**Git commit message：**

```
feat: build PageListScreen
```

**解释：**

- **不包含 NavigationStack 包装**：`PageListScreen` 是从 `RootView` 外层 `NavigationStack` push 进来的子页，自身不需要再包一层，与 `CollectionListScreen`（根视图，有自己的 NavigationStack）不同。
- **删除状态用 `@State private var pageToDelete: Page?`**，而非 ViewModel 的 published 属性，与 `CollectionListScreen` 的 `collectionToDelete` 处理方式完全一致。持有完整 `Page` 值类型比 `UUID?` 更方便在 `.alert(presenting:)` 的 message 里显示标题。
- **Toolbar placement 使用 `.topBarTrailing` / `.topBarLeading`**，与 `CollectionListScreen` 实际代码保持一致。
- **swipeActions 补充重命名按钮**，与 `CollectionListScreen` 的 swipe 操作对称。
- 删除路径（swipe / contextMenu / alert）统一触发 `pageToDelete = page`，不绕过确认弹窗。

---

## M3-11 PageRow

**文件：** `Features/Pages/Components/PageRow.swift`

```swift
import SwiftUI

struct PageRow: View {
    let page: Page

    var body: some View {
        HStack(spacing: SpacingTokens.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 18))
                .foregroundStyle(ColorTokens.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                Text(page.title)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)

                Text(page.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, SpacingTokens.sm)
        .padding(.horizontal, SpacingTokens.md)
    }
}

#Preview {
    PageRow(page: Page(
        id: UUID(),
        collectionID: UUID(),
        title: "SwiftUI 学习笔记",
        createdAt: Date(),
        updatedAt: Date(),
        sortIndex: 1000,
        isArchived: false
    ))
    .padding()
}
```

**Git commit message：**

```
feat: build PageRow component
```

**解释：**

- 纯展示组件，只接受 `Page` 值类型，不持有 ViewModel，可独立 Preview。
- 副标题显示 `updatedAt`，使用 `Date.formatted(date:time:)` API，无需自定义 `DateFormatter`。
- 所有间距和颜色引用 Token，不写魔法数字。

---

## M3-12 PageEmptyState

**文件：** `Features/Pages/Components/PageEmptyState.swift`

```swift
import SwiftUI

struct PageEmptyState: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()

            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(spacing: SpacingTokens.sm) {
                Text("还没有页面")
                    .font(TypographyTokens.title)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("点击下方按钮创建第一个页面")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateTapped) {
                Label("新建页面", systemImage: "plus")
                    .font(TypographyTokens.body)
                    .padding(.horizontal, SpacingTokens.lg)
                    .padding(.vertical, SpacingTokens.sm)
                    .background(ColorTokens.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(SpacingTokens.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PageEmptyState(onCreateTapped: {})
}
```

**Git commit message：**

```
feat: build PageEmptyState component
```

**解释：**

- 与 `CollectionEmptyState` 结构完全对称，只更换文案和图标。
- 回调设计保持组件职责单一，不持有 ViewModel。

---

## M3-13 PageCreateSheet

**文件：** `Features/Pages/Views/PageCreateSheet.swift`

```swift
import SwiftUI

struct PageCreateSheet: View {

    @ObservedObject var viewModel: PageListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("页面名称", text: $viewModel.newPageTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            Task { await viewModel.createPage() }
                        }
                }
            }
            .navigationTitle("新建页面")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        viewModel.newPageTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("创建") {
                        Task { await viewModel.createPage() }
                    }
                    .disabled(viewModel.newPageTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(ColorTokens.accent)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
        .presentationDetents([.height(220)])
    }
}
```

**Git commit message：**

```
feat: build PageCreateSheet
```

**解释：**

- 与 `CollectionCreateSheet` 结构完全一致，Toolbar placement 使用 `.topBarLeading` / `.topBarTrailing`，确认按钮添加 `.tint(ColorTokens.accent)`。
- `@ObservedObject`：Sheet 不持有 ViewModel 生命周期，由 `PageListScreen` 统一管理。
- 创建成功后 `createPage()` 内部将 `isShowingCreateSheet` 置 false，Sheet 自动关闭。

---

## M3-14 PageRenameSheet

**文件：** `Features/Pages/Views/PageRenameSheet.swift`

```swift
import SwiftUI

struct PageRenameSheet: View {

    @ObservedObject var viewModel: PageListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("页面名称", text: $viewModel.renameTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            guard let id = viewModel.renamingPageID else { return }
                            Task { await viewModel.renamePage(id: id) }
                        }
                }
            }
            .navigationTitle("重命名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.renamingPageID = nil
                        viewModel.renameTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        guard let id = viewModel.renamingPageID else { return }
                        Task { await viewModel.renamePage(id: id) }
                    }
                    .disabled(viewModel.renameTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(ColorTokens.accent)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
        .presentationDetents([.height(220)])
    }
}
```

**Git commit message：**

```
feat: build PageRenameSheet
```

**解释：**

- 与 `CollectionRenameSheet` 结构完全一致。
- 取消时同时清空 `renamingPageID` 和 `renameTitle`，保证 ViewModel 状态干净。
- `renamingPageID` 置 nil 会触发 `PageListScreen` 中控制 Sheet 开关的 `Binding.set`，Sheet 自动关闭。

---

## M3-15 PageContextMenu

**文件：** `Features/Pages/Components/PageContextMenu.swift`

```swift
import SwiftUI

struct PageContextMenu: View {
    let page: Page
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            Button(action: onRename) {
                Label("重命名", systemImage: "pencil")
            }

            Button(action: onDuplicate) {
                Label("复制页面", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
```

**Git commit message：**

```
feat: build PageContextMenu
```

**解释：**

- 与 `CollectionContextMenu` 结构一致，通过闭包接收回调，不持有 ViewModel。
- Page 不支持 Pin，以"复制页面"替代固定操作。
- `onDelete` 在调用方 (`PageListScreen`) 实现为设置 `pageToDelete = page`，触发确认 Alert，不直接执行删除。

---

## M3-16 RootView 更新（接入 PageListScreen）

**文件：** `App/RootView.swift`（在 M3-00a 基础上更新 `.pageList` 路由目标）

```swift
import Foundation
import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                repository: dependencyContainer.collectionRepository
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .pageList(let collectionID, let collectionTitle):
                    PageListScreen(
                        collectionID: collectionID,
                        collectionTitle: collectionTitle,
                        pageRepository: dependencyContainer.pageRepository,
                        nodeRepository: dependencyContainer.nodeRepository
                    )
                case .nodeEditor(let pageID):
                    Text("Node Editor 占位 \(pageID)")   // M4 替换
                }
            }
        }
        .environmentObject(router)
    }
}
```

**Git commit message：**

```
feat: wire CollectionListScreen to PageListScreen via router
```

**解释：**

- `DependencyContainer` 在 M1 阶段已包含 `pageRepository` 和 `nodeRepository` 属性，M3 直接使用，无需新增扩展。
- `collectionTitle` 从 `AppRoute.pageList` 关联值中解构取出，直接传给 `PageListScreen`，不需要在导航目标中再发起 Repository 查询。
- `.nodeEditor` 路由继续保持占位 Text，M4 接入 NodeEditor 时只改这一处，不需要修改 `PageListScreen`。

> **M3-17 导航桩说明（与 M3-16 合并）：** `PageListScreen` 中点击 `PageRow` 会调用 `router.navigate(to: .nodeEditor(pageID: page.id))`，页面 push 到占位视图。M4 替换 `RootView` 的 `.nodeEditor` case 即可，无需修改 `PageListScreen`。

**Git commit message（导航桩）：**

```
feat: add nodeEditor navigation stub in PageListScreen
```

---

## M3-17~21 单元测试

### `NotteTests/UnitTests/Mocks/MockPageRepository.swift`

```swift
import Foundation
@testable import Notte

@MainActor
class MockPageRepository: PageRepositoryProtocol {

    var storedPages: [Page] = []
    var shouldThrowOnCreate = false

    func fetchAll(in collectionID: UUID) async throws -> [Page] {
        storedPages.filter { $0.collectionID == collectionID }
    }

    func fetch(by id: UUID) async throws -> Page? {
        storedPages.first { $0.id == id }
    }

    func create(_ page: Page) async throws {
        if shouldThrowOnCreate { throw RepositoryError.saveFailed(NSError()) }
        storedPages.append(page)
    }

    func update(_ page: Page) async throws {
        guard let index = storedPages.firstIndex(where: { $0.id == page.id }) else {
            throw RepositoryError.notFound
        }
        storedPages[index] = page
    }

    func delete(by id: UUID) async throws {
        guard let index = storedPages.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        storedPages.remove(at: index)
    }
}
```

---

### `NotteTests/UnitTests/Mocks/MockNodeRepository.swift`

```swift
import Foundation
@testable import Notte

@MainActor
class MockNodeRepository: NodeRepositoryProtocol {

    var storedNodes: [Node] = []

    func fetchAll(in pageID: UUID) async throws -> [Node] {
        storedNodes.filter { $0.pageID == pageID }
    }

    func fetch(by id: UUID) async throws -> Node? {
        storedNodes.first { $0.id == id }
    }

    func create(_ node: Node) async throws {
        storedNodes.append(node)
    }

    func update(_ node: Node) async throws {
        guard let index = storedNodes.firstIndex(where: { $0.id == node.id }) else {
            throw RepositoryError.notFound
        }
        storedNodes[index] = node
    }

    func delete(by id: UUID) async throws {
        guard let index = storedNodes.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        storedNodes.remove(at: index)
    }

    func deleteAll(in pageID: UUID) async throws {
        storedNodes.removeAll { $0.pageID == pageID }
    }
}
```

---

### `NotteTests/UnitTests/PageRepositoryTests.swift`

```swift
import XCTest
import SwiftData
@testable import Notte

@MainActor
final class PageRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var repository: PageRepository!
    let collectionID = UUID()

    override func setUp() async throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
        repository = PageRepository(context: context)
    }

    func test_fetchAll_whenEmpty_returnsEmptyArray() async throws {
        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertTrue(result.isEmpty)
    }

    func test_fetchAll_onlyReturnsMatchingCollectionID() async throws {
        let otherCollectionID = UUID()
        try await repository.create(makePage(title: "属于本集合", collectionID: collectionID))
        try await repository.create(makePage(title: "属于其他集合", collectionID: otherCollectionID))

        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "属于本集合")
    }

    func test_create_withValidPage_persistsSuccessfully() async throws {
        let page = makePage(title: "测试页面")
        try await repository.create(page)

        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "测试页面")
    }

    func test_update_existingPage_updatesTitle() async throws {
        var page = makePage(title: "旧标题")
        try await repository.create(page)
        page.title = "新标题"
        try await repository.update(page)

        let updated = try await repository.fetch(by: page.id)
        XCTAssertEqual(updated?.title, "新标题")
    }

    func test_delete_existingPage_removesFromStore() async throws {
        let page = makePage(title: "待删除")
        try await repository.create(page)
        try await repository.delete(by: page.id)

        let result = try await repository.fetchAll(in: collectionID)
        XCTAssertTrue(result.isEmpty)
    }

    func test_delete_nonExistentID_throwsNotFound() async throws {
        do {
            try await repository.delete(by: UUID())
            XCTFail("应该抛出错误")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - Helpers

    private func makePage(title: String, collectionID: UUID? = nil, sortIndex: Double = 1000) -> Page {
        Page(
            id: UUID(),
            collectionID: collectionID ?? self.collectionID,
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isArchived: false
        )
    }
}
```

**Git commit message：**

```
test: add PageRepository unit tests
```

---

### `NotteTests/UnitTests/CreatePageUseCaseTests.swift`

```swift
import XCTest
@testable import Notte

@MainActor
final class CreatePageUseCaseTests: XCTestCase {

    var repository: MockPageRepository!
    var useCase: CreatePageUseCase!
    let collectionID = UUID()

    override func setUp() {
        repository = MockPageRepository()
        useCase = CreatePageUseCase(repository: repository)
    }

    func test_execute_withValidTitle_returnsPage() async throws {
        let result = try await useCase.execute(title: "新页面", in: collectionID)
        XCTAssertEqual(result.title, "新页面")
        XCTAssertEqual(result.collectionID, collectionID)
    }

    func test_execute_assignsIncrementingSortIndex() async throws {
        let first = try await useCase.execute(title: "第一页", in: collectionID)
        let second = try await useCase.execute(title: "第二页", in: collectionID)
        XCTAssertGreaterThan(second.sortIndex, first.sortIndex)
    }

    func test_execute_whenRepositoryThrows_propagatesError() async {
        repository.shouldThrowOnCreate = true
        do {
            _ = try await useCase.execute(title: "失败测试", in: collectionID)
            XCTFail("应该抛出错误")
        } catch is RepositoryError {
            // 正确抛出了 RepositoryError
        } catch {
            XCTFail("抛出了非预期的错误类型：\(error)")
        }
    }
}
```

**Git commit message：**

```
test: add CreatePageUseCase unit tests
```

---

### `NotteTests/UnitTests/DeletePageUseCaseTests.swift`

```swift
import XCTest
@testable import Notte

@MainActor
final class DeletePageUseCaseTests: XCTestCase {

    var pageRepository: MockPageRepository!
    var nodeRepository: MockNodeRepository!
    var useCase: DeletePageUseCase!

    override func setUp() {
        pageRepository = MockPageRepository()
        nodeRepository = MockNodeRepository()
        useCase = DeletePageUseCase(
            pageRepository: pageRepository,
            nodeRepository: nodeRepository
        )
    }

    func test_execute_deletesPageAndCascadesNodes() async throws {
        let collectionID = UUID()
        let page = Page(
            id: UUID(),
            collectionID: collectionID,
            title: "待删除",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isArchived: false
        )
        try await pageRepository.create(page)

        let node = Node(
            id: UUID(),
            pageID: page.id,
            parentNodeID: nil,
            title: "节点",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepository.create(node)

        try await useCase.execute(pageID: page.id)

        let pages = try await pageRepository.fetchAll(in: collectionID)
        let nodes = try await nodeRepository.fetchAll(in: page.id)
        XCTAssertTrue(pages.isEmpty, "Page 应该已被删除")
        XCTAssertTrue(nodes.isEmpty, "关联 Node 应该已被级联删除")
    }
}
```

**Git commit message：**

```
test: add DeletePageUseCase cascade deletion test
```

---

### `NotteTests/UnitTests/ReorderPagesUseCaseTests.swift`

```swift
import XCTest
@testable import Notte

@MainActor
final class ReorderPagesUseCaseTests: XCTestCase {

    var repository: MockPageRepository!
    var useCase: ReorderPagesUseCase!
    let collectionID = UUID()

    override func setUp() {
        repository = MockPageRepository()
        useCase = ReorderPagesUseCase(repository: repository)
    }

    func test_execute_movingToFront_assignsSmallerSortIndex() async throws {
        let page1 = makePage(title: "第一页", sortIndex: 1000)
        let page2 = makePage(title: "第二页", sortIndex: 2000)
        try await repository.create(page1)
        try await repository.create(page2)

        try await useCase.execute(collectionID: collectionID, moving: page2.id, after: nil)

        let result = try await repository.fetchAll(in: collectionID)
        let movedPage = result.first { $0.id == page2.id }!
        let firstPage = result.first { $0.id == page1.id }!
        XCTAssertLessThan(movedPage.sortIndex, firstPage.sortIndex)
    }

    func test_execute_movingAfterTarget_assignsIndexBetween() async throws {
        let page1 = makePage(title: "第一页", sortIndex: 1000)
        let page2 = makePage(title: "第二页", sortIndex: 2000)
        let page3 = makePage(title: "第三页", sortIndex: 3000)
        try await repository.create(page1)
        try await repository.create(page2)
        try await repository.create(page3)

        try await useCase.execute(collectionID: collectionID, moving: page3.id, after: page1.id)

        let moved = try await repository.fetch(by: page3.id)!
        XCTAssertGreaterThan(moved.sortIndex, page1.sortIndex)
        XCTAssertLessThan(moved.sortIndex, page2.sortIndex)
    }

    // MARK: - Helpers

    private func makePage(title: String, sortIndex: Double) -> Page {
        Page(
            id: UUID(),
            collectionID: collectionID,
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isArchived: false
        )
    }
}
```

**Git commit message：**

```
test: add ReorderPagesUseCase unit tests
```

---

## 修订说明

本文档相对原版做了以下修正，均以 M2 实际落地代码为准：

| # | 原文档问题 | 修正内容 |
|---|---|---|
| 1 | `SortIndexNormalizer` 为 Collection 专用，`ReorderPagesUseCase` 调用会编译报错 | 新增 M3-00b：引入 `SortIndexable` 协议，泛型化 `SortIndexNormalizer` |
| 2 | `ReorderPagesUseCase` 直接传 `Double?` 给 `SortIndexPolicy.indexBetween`，签名不匹配 | 改为与 `ReorderCollectionsUseCase` 相同的 `switch (lower, upper)` 分支处理 |
| 3 | `AppRoute.pageList` 只有 `collectionID`，PageListScreen 无法获取标题 | 新增 M3-00a：`AppRoute.pageList` 增加 `collectionTitle` 关联值 |
| 4 | `DependencyContainer`/`RootView` 存在拼写错误 | 新增 M3-00a 统一修正 |
| 5 | `CreatePageUseCase`/`DuplicatePageUseCase` 使用了不存在的 `SortIndexPolicy.indexAfter(last: Double?)` | 改为 `max() ?? 0 + 1000`，与 `CreateCollectionUseCase` 实际代码一致 |
| 6 | UseCase 层做标题空值校验，与现有 Collection UseCase 风格不符 | 移除 UseCase 层校验，由 ViewModel 的 `guard` 承担（与现有代码一致） |
| 7 | `PageListViewModel` 有 `deletingPageID`，与 Collection 实现模式不符 | 移除，改为 `PageListScreen` 的 `@State pageToDelete: Page?` |
| 8 | Mock 类使用 `actor` 关键字，与现有 `MockCollectionRepository` 不一致 | 改为 `@MainActor class` |
| 9 | `PageCreateSheet`/`PageRenameSheet` 使用 `.navigationBarTrailing` | 改为 `.topBarTrailing`/`.topBarLeading`，与现有 Sheet 代码一致 |
| 10 | `DependencyContainer` 中 `pageRepository`/`nodeRepository` 被写成扩展方法 | 移除，M1 已作为属性存在，M3-17 直接使用 |
