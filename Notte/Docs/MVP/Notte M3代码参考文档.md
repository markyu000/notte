# Notte M3 代码参考文档

> 本文档包含 M3（Pages）阶段所有 issue 的文件路径、代码内容与解释。  
> M3 目标：Collection → Page 导航稳定，Page 增删改查、排序、复制全部成立，级联删除正确。

---

## 分支

```
feature/m3-page-module
```

## 目录

1. [M3-01 PageRepositoryProtocol 升级](#m3-01-pagerepositoryprotocol-升级)
2. [M3-02 FetchPagesByCollectionUseCase](#m3-02-fetchpagesbycollectionusecase)
3. [M3-03 CreatePageUseCase](#m3-03-createpageusecase)
4. [M3-04 RenamePageUseCase](#m3-04-renamepageusecase)
5. [M3-05 DeletePageUseCase（含级联删除）](#m3-05-deletepageusecase含级联删除)
6. [M3-06 DuplicatePageUseCase](#m3-06-duplicatepageusecase)
7. [M3-07 ReorderPagesUseCase](#m3-07-reorderpagesusecase)
8. [M3-08 PageRepository 完整实现](#m3-08-pagerepository-完整实现)
9. [M3-09 PageListViewModel](#m3-09-pagelistviewmodel)
10. [M3-10 PageListScreen](#m3-10-pagelistscreen)
11. [M3-11 PageRow](#m3-11-pagerow)
12. [M3-12 PageEmptyState](#m3-12-pageemptystate)
13. [M3-13 PageCreateSheet](#m3-13-pagecreatesheet)
14. [M3-14 PageRenameSheet](#m3-14-pagerenaamesheet)
15. [M3-15 PageDeleteDialog](#m3-15-pagedeletedialog)
16. [M3-16 PageContextMenu](#m3-16-pagecontextmenu)
17. [M3-17 RootView 更新（接入 PageListScreen）](#m3-17-rootview-更新接入-pagelistscreen)
18. [M3-18 PageListScreen 导航桩（进入 NodeEditor）](#m3-18-pagelistscreen-导航桩进入-nodeeditor)
19. [M3-19~23 单元测试](#m3-1923-单元测试)

---

## M3-01 PageRepositoryProtocol 升级

**文件：** `Domain/Protocols/PageRepositoryProtocol.swift`（在 M1 骨架基础上更新）

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

**Git commit message：**

```
feat: upgrade PageRepositoryProtocol to async throws
```

**解释：**

- M1 阶段的 `PageRepositoryProtocol` 方法签名是同步 `throws`，作为骨架占位。M3 开始真正实现 Page 模块，将协议升级为 `async throws`，与 M2 中 `CollectionRepositoryProtocol` 的升级方式完全对称。
- `fetchAll(in collectionID:)` 带 `collectionID` 参数，确保每次查询只返回属于当前 Collection 的 Page，不在 UseCase 层做全量过滤。
- `NodeRepositoryProtocol` 和 `BlockRepositoryProtocol` 在 M4 用到时再同步升级，M3 不动。
- `PageRepository` 的骨架实现（M1 已建）需同步将方法签名改为 `async throws`，详见 M3-08。

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

- 与 `FetchCollectionsUseCase` 结构对称，只是没有 Pin 分组逻辑——Page 不支持固定，只按 `sortIndex` 升序排列。
- 排序逻辑放在 UseCase 层而不是 ViewModel 的计算属性中，确保所有调用方拿到的顺序一致。
- `repository.fetchAll(in: collectionID)` 由数据库层做 `collectionID` 过滤，不在内存中全量加载再筛选，保持 Repository 职责清晰。

---

## M3-03 CreatePageUseCase

**文件：** `Features/Pages/UseCases/CreatePageUseCase.swift`

```swift
import Foundation

struct CreatePageUseCase {
    let repository: PageRepositoryProtocol

    func execute(title: String, in collectionID: UUID) async throws -> Page {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw AppError.validationFailure("页面名称不能为空")
        }

        let existing = try await repository.fetchAll(in: collectionID)
        let lastIndex = existing.map(\.sortIndex).max()
        let newSortIndex = SortIndexPolicy.indexAfter(last: lastIndex)

        let page = Page(
            id: UUID(),
            collectionID: collectionID,
            title: trimmed,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: newSortIndex,
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

- 与 `CreateCollectionUseCase` 的实现思路完全一致，校验 title 非空后用 `SortIndexPolicy.indexAfter(last:)` 计算新 `sortIndex`，将 Page 排在已有条目末尾。
- `SortIndexPolicy` 是 M1 已定义的静态工具，这里直接复用，不重复实现插入逻辑。
- `collectionID` 作为参数传入，UseCase 不需要自己查询 Collection，职责边界清晰。
- 返回新建的 `Page`，ViewModel 可以直接用于更新本地状态或跳转。

---

## M3-04 RenamePageUseCase

**文件：** `Features/Pages/UseCases/RenamePageUseCase.swift`

```swift
import Foundation

struct RenamePageUseCase {
    let repository: PageRepositoryProtocol

    func execute(id: UUID, newTitle: String) async throws {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw AppError.validationFailure("页面名称不能为空")
        }
        guard var page = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        page.title = trimmed
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

- 与 `RenameCollectionUseCase` 结构对称：校验 → fetch → 修改 → update。
- `page.updatedAt = Date()` 确保每次重命名都更新时间戳，`PageRow` 可以用它显示"最近修改"。
- `guard var page` 而不是 `guard let`，因为需要在后面修改 `page` 的属性（值类型 `Page` 必须用 `var` 才能修改）。
- `AppError.repositoryError(RepositoryError.notFound)` 而不是直接抛 `RepositoryError`，让上层 ViewModel 统一处理 `AppError` 类型。

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

- `DeletePageUseCase` 依赖两个 Repository：`pageRepository` 和 `nodeRepository`。UseCase 层负责编排跨 Repository 的操作，Repository 层各自只做单表操作。
- `nodeRepository.deleteAll(in: pageID)` 使用 M1 在 `NodeRepositoryProtocol` 上定义的 `deleteAll` 方法，该方法在 M1 骨架中已预留，M4 会提供完整实现。M3 阶段 Node 表为空，调用不会造成问题，但调用链已经接好，M4 接入编辑器后自动生效。
- 删除顺序必须先删 Node，再删 Page。反向操作在部分数据库引擎中可能触发外键约束问题，保持顺序是正确的实践。
- 此 UseCase 不处理 Block 的级联删除，Block 的清理由 `NodeRepository.deleteAll` 内部处理（M4 实现时完成），UseCase 层不需要感知。

---

## M3-06 DuplicatePageUseCase

**文件：** `Features/Pages/UseCases/DuplicatePageUseCase.swift`

```swift
import Foundation

struct DuplicatePageUseCase {
    let repository: PageRepositoryProtocol

    func execute(pageID: UUID) async throws -> Page {
        guard let original = try await repository.fetch(by: pageID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }

        let existing = try await repository.fetchAll(in: original.collectionID)
        let lastIndex = existing.map(\.sortIndex).max()
        let newSortIndex = SortIndexPolicy.indexAfter(last: lastIndex)

        let duplicate = Page(
            id: UUID(),
            collectionID: original.collectionID,
            title: "\(original.title) 副本",
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: newSortIndex,
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

- M3 阶段 `DuplicatePageUseCase` 只复制 Page 元数据（title、collectionID），不深拷贝 Node 和 Block。Node 的深拷贝在 M4 的 Node 编辑器稳定后补充，避免 M3 范围过重。
- 副本的 title 格式为 `"原标题 副本"`，是 Apple 系 App 的惯例命名方式。
- 副本分配新的 UUID 和新的 `sortIndex`，排在当前 Collection 所有 Page 之后。
- `createdAt` 和 `updatedAt` 均设为 `Date()`，副本是全新的条目，不继承原 Page 的时间戳。

---

## M3-07 ReorderPagesUseCase

**文件：** `Features/Pages/UseCases/ReorderPagesUseCase.swift`

```swift
import Foundation

struct ReorderPagesUseCase {
    let repository: PageRepositoryProtocol

    func execute(collectionID: UUID, moving id: UUID, after targetID: UUID?) async throws {
        var pages = try await repository.fetchAll(in: collectionID)
        pages.sort { $0.sortIndex < $1.sortIndex }

        guard let movingIndex = pages.firstIndex(where: { $0.id == id }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }

        let lower: Double?
        let upper: Double?

        if let targetID {
            guard let targetIndex = pages.firstIndex(where: { $0.id == targetID }) else {
                throw AppError.repositoryError(RepositoryError.notFound)
            }
            lower = pages[targetIndex].sortIndex
            upper = targetIndex + 1 < pages.count && pages[targetIndex + 1].id != id
                ? pages[targetIndex + 1].sortIndex
                : nil
        } else {
            lower = nil
            upper = pages.first?.sortIndex
        }

        let newIndex = SortIndexPolicy.indexBetween(before: lower, after: upper)

        var moving = pages[movingIndex]
        moving.sortIndex = newIndex
        moving.updatedAt = Date()
        try await repository.update(moving)

        await SortIndexNormalizer.normalizeIfNeeded(
            entities: try await repository.fetchAll(in: collectionID),
            sortIndexKeyPath: \.sortIndex,
            update: { page in
                var p = page
                p.updatedAt = Date()
                try await repository.update(p)
            }
        )
    }
}
```

**Git commit message：**

```
feat: add ReorderPagesUseCase
```

**解释：**

- 与 `ReorderCollectionsUseCase` 结构完全对称，只是增加了 `collectionID` 参数，因为 Page 查询需要按 `collectionID` 过滤。
- `targetID == nil` 表示移动到最前面，此时 `lower = nil`，`upper` 取当前第一条的 `sortIndex`，由 `SortIndexPolicy.indexBetween` 处理 `lower == nil` 的边界情况。
- `SortIndexNormalizer.normalizeIfNeeded` 在排序后检查间隔是否过小，必要时重新归一化，复用 M2 已实现的工具，不重复实现。
- 计算新 index 时要排除 moving 条目自身，防止 upper 取到自己的旧值（通过 `pages[targetIndex + 1].id != id` 判断）。

---

## M3-08 PageRepository 完整实现

**文件：** `Data/Repositories/PageRepository.swift`（在 M1 骨架基础上更新）

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
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(by id: UUID) async throws -> Page? {
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.toDomain()
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
        let descriptor = FetchDescriptor<PageModel>(
            predicate: #Predicate { $0.id == page.id }
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

- 与 `CollectionRepository` 的实现模式完全一致，`FetchDescriptor` + `#Predicate` + `context.save()`，只是把 `CollectionModel` 换成 `PageModel`。
- `fetchAll(in:)` 的 `FetchDescriptor` 在数据库层做 `collectionID` 过滤，并附带 `sortBy: [SortDescriptor(\.sortIndex)]` 让 SwiftData 在查询时直接排好序，减少内存中的排序操作。
- `update` 里没有修改 `collectionID`，Page 一旦创建就不会换 Collection（MVP 阶段不支持跨 Collection 移动 Page）。
- `delete` 只删除 `PageModel` 本身，Node 的清理由 `DeletePageUseCase` 在调用 `pageRepository.delete` 之前通过 `nodeRepository.deleteAll(in:)` 处理。

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

    // MARK: - 删除确认状态
    @Published var deletingPageID: UUID?

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
            deletingPageID = nil
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

- `collectionTitle` 也作为参数传入，用于 `PageListScreen` 的 `.navigationTitle`，ViewModel 统一持有所有需要展示的数据，View 不需要自己向上查询 Collection。
- `init` 接受 `pageRepository` 和 `nodeRepository` 两个依赖，因为 `DeletePageUseCase` 需要两者。调用方（`PageListScreen`）从 `DependencyContainer` 分别取出传入。
- `deletingPageID` 状态用于控制删除确认 Alert 的显示，与 M2 中 `renamingCollectionID` 的模式一致：非 nil 时显示 Alert，操作完成或取消后置回 nil。
- 所有 action 执行成功后统一调用 `await loadPages()` 刷新，不手动修改内存数组，保持数据源唯一（数据库是唯一真相）。

---

## M3-10 PageListScreen

**文件：** `Features/Pages/Views/PageListScreen.swift`

```swift
import SwiftUI

struct PageListScreen: View {

    @StateObject private var viewModel: PageListViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var editMode: EditMode = .inactive

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
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.pages.isEmpty {
                PageEmptyState {
                    viewModel.isShowingCreateSheet = true
                }
            } else {
                pageList
            }
        }
        .navigationTitle(viewModel.collectionTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.isShowingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            PageCreateSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.renamingPageID != nil },
            set: { if !$0 { viewModel.renamingPageID = nil } }
        )) {
            PageRenameSheet(viewModel: viewModel)
        }
        .alert("删除页面", isPresented: Binding(
            get: { viewModel.deletingPageID != nil },
            set: { if !$0 { viewModel.deletingPageID = nil } }
        ), presenting: viewModel.deletingPageID) { pageID in
            PageDeleteDialog(pageID: pageID, viewModel: viewModel)
        } message: { _ in
            Text("此操作将删除页面及其全部内容，无法恢复。")
        }
        .alert("出错了", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        ), presenting: viewModel.error) { _ in
            Button("好", role: .cancel) { viewModel.error = nil }
        } message: { error in
            Text(error.errorDescription ?? "未知错误")
        }
        .task {
            await viewModel.loadPages()
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
                                viewModel.deletingPageID = page.id
                            }
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deletingPageID = page.id
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
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

- 结构与 `CollectionListScreen` 高度对称，三态切换（loading / empty / list）、toolbar、EditMode、Sheet、Alert 的组织方式完全一致，便于维护。
- 删除操作走 `viewModel.deletingPageID = page.id` 而不是直接执行，先显示确认 Alert，保护用户不误删。这与 Collection 删除直接执行的做法不同，因为删除 Page 涉及级联删除所有内容，破坏性更强，需要二次确认。
- `.swipeActions` 中删除同样走 `deletingPageID` 触发 Alert，不绕过二次确认。
- `router.navigate(to: .nodeEditor(pageID: page.id))` 是 M3 到 M4 的导航接口，M3 阶段 `.nodeEditor` 路由指向一个占位 View，M4 替换为真正的 NodeEditor。

---

## M3-11 PageRow

**文件：** `Features/Pages/Views/PageRow.swift`

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

- `PageRow` 是纯展示组件，只接受 `Page` 值类型，不持有 ViewModel，可独立复用和 Preview。
- 副标题显示 `updatedAt`，使用 Swift 5.5 引入的 `Date.formatted(date:time:)` API，格式简洁（如"2026年4月4日"），不写自定义 `DateFormatter`。
- `Image(systemName: "doc.text")` 用 SF Symbol 作为 Page 的图标，`ColorTokens.accent` 上色，与整体配色一致。
- `lineLimit(1)` 防止长标题撑开行高，超出部分用省略号截断。
- 所有间距引用 `SpacingTokens`，不写魔法数字。

---

## M3-12 PageEmptyState

**文件：** `Features/Pages/Views/PageEmptyState.swift`

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

- 与 `CollectionEmptyState` 结构完全对称，只更换了文案和图标（`doc.badge.plus`）。
- `onCreateTapped: () -> Void` 回调设计保持组件职责单一，不持有 ViewModel。
- 两个 `Spacer()` 上下夹住内容，使其在屏幕垂直方向居中。

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.newPageTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        Task { await viewModel.createPage() }
                    }
                    .disabled(viewModel.newPageTitle.trimmingCharacters(in: .whitespaces).isEmpty)
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

- 与 `CollectionCreateSheet` 结构完全一致，将绑定字段改为 `viewModel.newPageTitle`，操作方法改为 `viewModel.createPage()`。
- `@ObservedObject` 而不是 `@StateObject`，Sheet 不持有 ViewModel 生命周期，由 `PageListScreen` 统一管理。
- `.presentationDetents([.height(220)])` 以小面板形式弹出，符合"轻量创建"的交互意图，与 Collection 创建体验一致。
- 创建成功后 `createPage()` 内部会将 `isShowingCreateSheet` 置为 false，Sheet 自动关闭；取消时手动 `dismiss()` 并清空标题。

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

- 与 `CollectionRenameSheet` 结构完全一致，`renamingCollectionID` → `renamingPageID`，`renameCollection` → `renamePage`。
- 取消时同时清空 `renamingPageID` 和 `renameTitle`，保证 ViewModel 状态干净，下次打开不残留旧值。
- `renamingPageID` 置 nil 会触发 `PageListScreen` 中控制 Sheet 开关的 `Binding.set`，Sheet 自动关闭。

---

## M3-15 PageDeleteDialog

**文件：** `Features/Pages/Views/PageDeleteDialog.swift`

```swift
import SwiftUI

struct PageDeleteDialog: View {

    let pageID: UUID
    @ObservedObject var viewModel: PageListViewModel

    var body: some View {
        Group {
            Button("删除", role: .destructive) {
                Task { await viewModel.deletePage(id: pageID) }
            }
            Button("取消", role: .cancel) {
                viewModel.deletingPageID = nil
            }
        }
    }
}
```

**Git commit message：**

```
feat: build PageDeleteDialog
```

**解释：**

- 与 `CollectionDeleteDialog` 结构对称，只提供 Alert 的按钮内容，被嵌入 `PageListScreen` 的 `.alert` 修饰器中。
- 删除 Page 有级联风险（所有 Node 一并删除），破坏性更强，因此在 `PageListScreen` 的 `.alert` 里额外附加了 `message: "此操作将删除页面及其全部内容，无法恢复。"` 的提示文案，对用户更加透明。
- 取消按钮在这里手动将 `viewModel.deletingPageID = nil` 置空（而不仅仅依赖 Alert 消失后的 Binding set 回调），确保状态在所有路径下都正确清理。

---

## M3-16 PageContextMenu

**文件：** `Features/Pages/Views/PageContextMenu.swift`

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

- 与 `CollectionContextMenu` 结构一致，通过闭包接收回调，不持有 ViewModel，职责单一，可复用。
- Page 不支持 Pin，所以没有固定按钮；替换为"复制页面"，对应 `DuplicatePageUseCase`。
- `Divider()` 将破坏性操作（删除）与普通操作（重命名、复制）视觉隔开。
- 删除回调 `onDelete` 在调用方（`PageListScreen`）被实现为设置 `viewModel.deletingPageID = page.id`，弹出确认 Alert，不直接执行删除。

---

## M3-17 RootView 更新（接入 PageListScreen）

**文件：** `App/RootView.swift`（在 M2-20 基础上更新 `.pageList` 路由目标）

```swift
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
                case .pageList(let collectionID):
                    PageListScreen(
                        collectionID: collectionID,
                        collectionTitle: dependencyContainer.collectionTitle(for: collectionID),
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

**补充：** `DependencyContainer` 需要新增 `pageRepository`、`nodeRepository` 属性，以及用于查询 Collection title 的辅助方法 `collectionTitle(for:)`：

```swift
// App/DependencyContainer.swift（在 M1 基础上补充）

extension DependencyContainer {
    var pageRepository: PageRepositoryProtocol {
        PageRepository(context: modelContext)
    }

    var nodeRepository: NodeRepositoryProtocol {
        NodeRepository(context: modelContext)
    }

    func collectionTitle(for collectionID: UUID) -> String {
        let repo = CollectionRepository(context: modelContext)
        // 同步读取，仅用于导航标题，容忍不存在时返回空串
        return (try? await repo.fetch(by: collectionID))?.title ?? ""
    }
}
```

> **注意：** `collectionTitle(for:)` 这里给出的是简化实现，实际上由于 SwiftData 的 `fetch` 是同步操作包在 `async` 函数里，可以在 `.navigationDestination` 的 View 构造阶段直接传入从 router path 里携带的 title（推荐做法是在 `AppRoute.pageList` 枚举的关联值中同时携带 `collectionTitle: String`）。具体取舍可根据 `AppRoute` 的定义决定，文档此处以传参最简方式示意。

**Git commit message（DependencyContainer）：**

```
feat: add pageRepository and nodeRepository to DependencyContainer
```

**解释：**

- M2 的 `RootView` 中 `.pageList` 路由指向 `Text("Page List 占位 \(collectionID)")`，M3 将其替换为真正的 `PageListScreen`。
- `dependencyContainer.pageRepository` 和 `dependencyContainer.nodeRepository` 由 `DependencyContainer` 统一提供，`PageListScreen` 和 `PageListViewModel` 不感知容器存在。
- `.nodeEditor` 路由的占位 Text 在 M4 替换，此 issue 只动 `.pageList` 分支。

---

## M3-18 PageListScreen 导航桩（进入 NodeEditor）

> 此 issue 在 M3-17 中已经一并完成：`RootView` 的 `.nodeEditor` 路由仍指向占位 `Text`，`PageListScreen` 中点击 `PageRow` 会调用 `router.navigate(to: .nodeEditor(pageID: page.id))`，页面会 push 到占位视图。M4 接入 NodeEditor 时直接替换 `RootView` 的 `.nodeEditor` case 即可，无需修改 `PageListScreen`。

**Git commit message：**

```
feat: add nodeEditor navigation stub in PageListScreen
```

---

## M3-19~23 单元测试

### `Tests/UnitTests/Mocks/MockPageRepository.swift`

```swift
import Foundation
@testable import Notte

actor MockPageRepository: PageRepositoryProtocol {

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

### `Tests/UnitTests/Mocks/MockNodeRepository.swift`

```swift
import Foundation
@testable import Notte

actor MockNodeRepository: NodeRepositoryProtocol {

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

### `Tests/UnitTests/PageRepositoryTests.swift`

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

    func test_delete_nonExistentID_throwsNotFound() async {
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

### `Tests/UnitTests/CreatePageUseCaseTests.swift`

```swift
import XCTest
@testable import Notte

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

    func test_execute_withEmptyTitle_throwsValidationFailure() async {
        do {
            _ = try await useCase.execute(title: "   ", in: collectionID)
            XCTFail("应该抛出 validationFailure")
        } catch let error as AppError {
            if case .validationFailure = error { } else {
                XCTFail("错误类型不符")
            }
        }
    }
}
```

**Git commit message：**

```
test: add CreatePageUseCase unit tests
```

---

### `Tests/UnitTests/DeletePageUseCaseTests.swift`

```swift
import XCTest
@testable import Notte

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

### `Tests/UnitTests/ReorderPagesUseCaseTests.swift`

```swift
import XCTest
@testable import Notte

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

**解释（测试整体）：**

- 所有测试均使用 `MockPageRepository` 和 `MockNodeRepository`（均声明为 `actor`），完全不依赖 SwiftData，保证测试速度快且无 I/O 副作用。
- `DeletePageUseCaseTests` 重点验证级联删除：Page 被删后，对应 Node 也应从 `nodeRepository` 中消失，这是 M3 验收的核心条件之一。
- Mock 放在 `Tests/UnitTests/Mocks/` 与 M2 的 `MockCollectionRepository` 并列，M4 会继续在此目录添加 `MockBlockRepository`。
- `PageRepositoryTests` 额外验证了 `fetchAll(in:)` 的 `collectionID` 过滤逻辑，确保不同 Collection 的 Page 互不干扰。

---

## 目录结构速览

M3 新增与修改的文件一览：

```
Notte/
├── App/
│   ├── RootView.swift                                  ← 更新：接入 PageListScreen
│   └── DependencyContainer.swift                      ← 更新：新增 pageRepository、nodeRepository
│
├── Features/
│   └── Pages/                                         ← 新增整个模块
│       ├── UseCases/
│       │   ├── FetchPagesByCollectionUseCase.swift
│       │   ├── CreatePageUseCase.swift
│       │   ├── RenamePageUseCase.swift
│       │   ├── DeletePageUseCase.swift
│       │   ├── DuplicatePageUseCase.swift
│       │   └── ReorderPagesUseCase.swift
│       ├── ViewModels/
│       │   └── PageListViewModel.swift
│       └── Views/
│           ├── PageListScreen.swift
│           ├── PageRow.swift
│           ├── PageEmptyState.swift
│           ├── PageCreateSheet.swift
│           ├── PageRenameSheet.swift
│           ├── PageDeleteDialog.swift
│           └── PageContextMenu.swift
│
├── Domain/
│   └── Protocols/
│       └── PageRepositoryProtocol.swift               ← 更新：方法签名改为 async throws
│
└── Data/
    └── Repositories/
        └── PageRepository.swift                       ← 更新：骨架 → 完整实现，async throws

Tests/
└── UnitTests/
    ├── PageRepositoryTests.swift
    ├── CreatePageUseCaseTests.swift
    ├── DeletePageUseCaseTests.swift
    ├── ReorderPagesUseCaseTests.swift
    └── Mocks/
        ├── MockPageRepository.swift
        └── MockNodeRepository.swift
```

---

> M3 Pages 全部完成。验收条件：从 Collection 正常进入 Page 列表，Page 增删改查、复制、排序全部成立，排序结果重启后保留，删除 Page 时关联 Node 同步清理，空状态清晰引导创建，单元测试全部通过。
