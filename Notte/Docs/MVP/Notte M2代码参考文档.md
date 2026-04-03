# Notte M2 代码参考文档

> 本文档包含 M2（Collections）阶段所有 issue 的文件路径、代码内容与解释。  
> M2 目标：首页完整，Collection 的增删改查、排序、固定全部成立。

---

## 目录

1. [M2-01 CollectionRepositoryProtocol 升级](#m2-01-collectionrepositoryprotocol-升级)
2. [M2-02 FetchCollectionsUseCase](#m2-02-fetchcollectionsusecase)
3. [M2-03 CreateCollectionUseCase](#m2-03-createcollectionusecase)
4. [M2-04 RenameCollectionUseCase](#m2-04-renamecollectionusecase)
5. [M2-05 DeleteCollectionUseCase](#m2-05-deletecollectionusecase)
6. [M2-06 PinCollectionUseCase](#m2-06-pincollectionusecase)
7. [M2-07 ReorderCollectionsUseCase](#m2-07-reordercollectionsusecase)
8. [M2-08 SortIndexNormalizer](#m2-08-sortindexnormalizer)
9. [M2-09 CollectionListViewModel](#m2-09-collectionlistviewmodel)
10. [M2-10 CollectionListScreen](#m2-10-collectionlistscreen)
11. [M2-11 CollectionCard](#m2-11-collectioncard)
12. [M2-12 CollectionEmptyState](#m2-12-collectionemptystate)
13. [M2-13 CollectionCreateSheet](#m2-13-collectioncreatesheet)
14. [M2-14 CollectionRenameSheet](#m2-14-collectionrenamesheet)
15. [M2-15 CollectionDeleteDialog](#m2-15-collectiondeletedialog)
16. [M2-16 CollectionContextMenu](#m2-16-collectioncontextmenu)
17. [M2-17 CollectionPinnedIndicator](#m2-17-collectionpinnedindicator)
18. [M2-18 AppError 补充 validationFailure](#m2-18-apperror-补充-validationfailure)
19. [M2-19 CollectionRepository 完整实现](#m2-19-collectionrepository-完整实现)
20. [M2-20 RootView 更新](#m2-20-rootview-更新)
21. [M2-21~26 单元测试](#m2-2126-单元测试)

---

## M2-01 CollectionRepositoryProtocol 升级

**文件：** `Domain/Protocols/CollectionRepositoryProtocol.swift`（在 M1 基础上更新）

```swift
import Foundation

protocol CollectionRepositoryProtocol {
    func fetchAll() async throws -> [Collection]
    func fetch(by id: UUID) async throws -> Collection?
    func create(_ collection: Collection) async throws
    func update(_ collection: Collection) async throws
    func delete(by id: UUID) async throws
}
```

**Git commit message：**

```
feat: upgrade CollectionRepositoryProtocol to async throws
```

**解释：**

- M1 阶段所有 Repository Protocol 方法签名是同步 `throws`，作为骨架占位。M2 开始真正实现 Collection 模块，将 `CollectionRepositoryProtocol` 升级为 `async throws`，让 UseCase 和 ViewModel 能在统一的 `async` 上下文中调用。
- 其他三个 Protocol（Page / Node / Block）在 M3~M4 用到时再同步升级，M2 不动。
- `CollectionRepository` 的实现也需要同步将方法签名改为 `async throws`，详见 M2-19。

---

## M2-02 FetchCollectionsUseCase

**分支：** `feature/collection-use-cases`  
**文件：** `Features/Collections/UseCases/FetchCollectionsUseCase.swift`

```swift
import Foundation

struct FetchCollectionsUseCase {
    let repository: CollectionRepositoryProtocol

    func execute() async throws -> [Collection] {
        let all = try await repository.fetchAll()
        // 固定的排前面，同组内按 sortIndex 升序
        return all.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.sortIndex < $1.sortIndex
        }
    }
}
```

**Git commit message：**

```
feat: add FetchCollectionsUseCase
```

**解释：**

- `async throws` 对应升级后的 Protocol，调用方用 `try await`。
- 排序逻辑（固定在前、同组按 `sortIndex`）放在 UseCase 里，不在 ViewModel 的计算属性。这样所有调用 `FetchCollectionsUseCase` 的地方都能得到一致的排序结果，ViewModel 拿到的 `collections` 直接是排好序的，不需要再处理。
- `if $0.isPinned != $1.isPinned { return $0.isPinned }` 的含义：两个条目固定状态不同时，固定的那个（`isPinned == true`）排在前面；固定状态相同时，按 `sortIndex` 升序排列。

---

## M2-03 CreateCollectionUseCase

**文件：** `Features/Collections/UseCases/CreateCollectionUseCase.swift`

```swift
import Foundation

struct CreateCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    @discardableResult
    func execute(title: String) async throws -> Collection {
        let all = try await repository.fetchAll()
        let maxIndex = all.map(\.sortIndex).max() ?? 0
        let entity = Collection(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: maxIndex + 1000,
            isPinned: false
        )
        try await repository.create(entity)
        return entity
    }
}
```

**Git commit message：**

```
feat: add CreateCollectionUseCase
```

**解释：**

- `@discardableResult` 标记返回值可以被忽略。ViewModel 在创建后直接重新 fetch 列表，通常不用这个返回值；测试时可以直接拿到结果做断言。
- `sortIndex` 取当前最大值加 1000，确保新条目插入到列表末尾，间隔足够大供后续拖动排序插入。
- `Collection` 初始化时没有传 `iconName` 和 `colorToken`，是因为 M1 的 `Collection` domain entity 中这两个字段有默认值 `nil`，M2 阶段不支持用户自定义图标和颜色。
- 标题的空字符串校验在 ViewModel 层做（调用前先 `guard !title.trimmingCharacters(...).isEmpty`），UseCase 不重复校验。

---

## M2-04 RenameCollectionUseCase

**文件：** `Features/Collections/UseCases/RenameCollectionUseCase.swift`

```swift
import Foundation

struct RenameCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(id: UUID, newTitle: String) async throws {
        guard var collection = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        collection.title = newTitle
        collection.updatedAt = Date()
        try await repository.update(collection)
    }
}
```

**Git commit message：**

```
feat: add RenameCollectionUseCase
```

**解释：**

- `guard var collection` 先查找再修改，找不到时以 `AppError.repositoryError(.notFound)` 提前退出。
- `var` 让 collection 可变，直接改字段后再传给 `repository.update`，不需要重新构造整个结构体。
- `updatedAt = Date()` 每次写操作都更新时间戳，是所有写操作的惯例。
- 新标题的空字符串校验在 ViewModel 层做，UseCase 不重复。

---

## M2-05 DeleteCollectionUseCase

**文件：** `Features/Collections/UseCases/DeleteCollectionUseCase.swift`

```swift
import Foundation

struct DeleteCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(id: UUID) async throws {
        try await repository.delete(by: id)
    }
}
```

**Git commit message：**

```
feat: add DeleteCollectionUseCase
```

**解释：**

- M2 阶段直接委托 Repository 删除，Repository 找不到记录时会抛 `RepositoryError.notFound`，错误自然向上传播到 ViewModel。
- M3 完成后需要在这里补充级联删除：先删除 Collection 下所有 Page（及其 Node、Block），再删除 Collection 本身。M2 阶段暂无 Page，不处理。

---

## M2-06 PinCollectionUseCase

**文件：** `Features/Collections/UseCases/PinCollectionUseCase.swift`

```swift
import Foundation

struct PinCollectionUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(id: UUID) async throws {
        guard var entity = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        entity.isPinned.toggle()
        entity.updatedAt = Date()
        try await repository.update(entity)
    }
}
```

**Git commit message：**

```
feat: add PinCollectionUseCase
```

**解释：**

- `entity.isPinned.toggle()` 在 UseCase 内部执行 toggle。调用方只需传 `id`，不需要知道当前的固定状态，接口更简洁。
- ViewModel 里写 `await pinUseCase.execute(id: collection.id)`，不需要自己计算 `!isPinned`。

---

## M2-07 ReorderCollectionsUseCase

**文件：** `Features/Collections/UseCases/ReorderCollectionsUseCase.swift`

```swift
import Foundation

struct ReorderCollectionsUseCase {
    let repository: CollectionRepositoryProtocol

    func execute(moving id: UUID, after targetID: UUID?) async throws {
        let all = try await repository.fetchAll()
            .sorted { $0.sortIndex < $1.sortIndex }

        let targetIndex = targetID.flatMap { tid in
            all.firstIndex { $0.id == tid }
        }

        let lower: Double? = targetIndex.map { all[$0].sortIndex }
        let upper: Double? = targetIndex.flatMap { idx in
            all.indices.contains(idx + 1) ? all[idx + 1].sortIndex : nil
        }

        let newIndex: Double
        switch (lower, upper) {
        case (nil, nil):
            newIndex = SortIndexPolicy.initialIndex()
        case (nil, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: 0, after: u)
        case (let l?, nil):
            newIndex = SortIndexPolicy.indexAfter(last: l)
        case (let l?, let u?):
            newIndex = SortIndexPolicy.indexBetween(before: l, after: u)
        }

        guard var collection = try await repository.fetch(by: id) else {
            throw AppError.repositoryError(.notFound)
        }
        collection.sortIndex = newIndex
        collection.updatedAt = Date()
        try await repository.update(collection)

        Task.detached {
            let latest = try await repository.fetchAll()
            try await SortIndexNormalizer.normalizeIfNeeded(latest) { updated in
                try await repository.update(updated)
            }
        }
    }
}
```

**Git commit message：**

```
feat: add ReorderCollectionsUseCase with sortIndex strategy
```

**解释：**

- 参数命名 `moving id: UUID, after targetID: UUID?` 让调用处读起来像自然语言：`execute(moving: id, after: targetID)`。`targetID` 为 `nil` 表示移动到最前面。
- `switch (lower, upper)` 覆盖四种情况：`(nil, nil)` 空列表用初始值；`(nil, u?)` 移到最前取 0 与第一个元素的中间值；`(l?, nil)` 移到最后取末尾元素之后的值；`(l?, u?)` 插到两元素之间取中间值。
- 每次拖动只修改被移动那一条记录的 `sortIndex`，O(1) 写入。
- `Task.detached` 在后台触发 normalize，不阻塞用户操作。normalize 通过闭包回调写入，`SortIndexNormalizer` 不直接持有 repository 引用，保持解耦。

---

## M2-08 SortIndexNormalizer

**文件：** `Shared/Utilities/SortIndexNormalizer.swift`

```swift
import Foundation

struct SortIndexNormalizer {

    /// 检查是否需要归一化，若需要则对每个条目调用 update 闭包。
    static func normalizeIfNeeded(
        _ items: [Collection],
        update: (Collection) async throws -> Void
    ) async throws {
        let sorted = items.sorted { $0.sortIndex < $1.sortIndex }

        let needsNormalization = zip(sorted, sorted.dropFirst()).contains { a, b in
            SortIndexPolicy.needsNormalization(before: a.sortIndex, after: b.sortIndex)
        }

        guard needsNormalization else { return }

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
feat: add SortIndexNormalizer utility
```

**解释：**

- `update: (Collection) async throws -> Void` 是写入闭包，调用方（`ReorderCollectionsUseCase`）传入 `{ try await repository.update($0) }`，让 `SortIndexNormalizer` 不直接依赖 Repository，保持纯工具类性质，便于测试。
- `SortIndexNormalizer` 只负责"检查 → 生成新 index → 调用写入"的流程编排，策略判断（`needsNormalization`）和 index 生成（`normalize`）委托给 M1 已定义的 `SortIndexPolicy`，不重复实现。
- `zip(sorted, sorted.dropFirst())` 遍历所有相邻对，只要有一对间隔小于 `SortIndexPolicy.minimumGap`（0.001）就触发整体归一化。

---

## M2-09 CollectionListViewModel

**文件：** `Features/Collections/ViewModels/CollectionListViewModel.swift`

```swift
import Foundation
import Combine

@MainActor
class CollectionListViewModel: ObservableObject {

    // MARK: - 数据状态
    @Published var collections: [Collection] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    // MARK: - 创建弹窗状态
    @Published var isShowingCreateSheet: Bool = false
    @Published var newCollectionTitle: String = ""

    // MARK: - 重命名状态
    @Published var renamingCollectionID: UUID?
    @Published var renameTitle: String = ""

    // MARK: - UseCases
    private let fetchUseCase: FetchCollectionsUseCase
    private let createUseCase: CreateCollectionUseCase
    private let renameUseCase: RenameCollectionUseCase
    private let deleteUseCase: DeleteCollectionUseCase
    private let pinUseCase: PinCollectionUseCase
    private let reorderUseCase: ReorderCollectionsUseCase

    init(repository: CollectionRepositoryProtocol) {
        self.fetchUseCase = FetchCollectionsUseCase(repository: repository)
        self.createUseCase = CreateCollectionUseCase(repository: repository)
        self.renameUseCase = RenameCollectionUseCase(repository: repository)
        self.deleteUseCase = DeleteCollectionUseCase(repository: repository)
        self.pinUseCase = PinCollectionUseCase(repository: repository)
        self.reorderUseCase = ReorderCollectionsUseCase(repository: repository)
    }

    // MARK: - 操作方法
    func loadCollections() async {
        isLoading = true
        defer { isLoading = false }
        do {
            collections = try await fetchUseCase.execute()
        } catch {
            self.error = error as? AppError
        }
    }

    func createCollection() async {
        guard !newCollectionTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await createUseCase.execute(title: newCollectionTitle)
            newCollectionTitle = ""
            isShowingCreateSheet = false
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func renameCollection(id: UUID) async {
        guard !renameTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await renameUseCase.execute(id: id, newTitle: renameTitle)
            renamingCollectionID = nil
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func deleteCollection(id: UUID) async {
        do {
            try await deleteUseCase.execute(id: id)
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func pinCollection(id: UUID) async {
        do {
            try await pinUseCase.execute(id: id)
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }

    func reorderCollection(moving id: UUID, after targetID: UUID?) async {
        do {
            try await reorderUseCase.execute(moving: id, after: targetID)
            await loadCollections()
        } catch {
            self.error = error as? AppError
        }
    }
}
```

**Git commit message：**

```
feat: add CollectionListViewModel with full state management
```

**解释：**

- `init(repository: CollectionRepositoryProtocol)` 直接接收 Repository，不经过 `DependencyContainer`。`CollectionListScreen` 通过 `@EnvironmentObject` 取到 `DependencyContainer`，从中取出 `collectionRepository` 再传入，ViewModel 本身不依赖 DI 容器，更易于单元测试（直接传 Mock）。
- 所有 action 方法都是 `async`，因为 UseCase 和 Repository 均为 `async throws`。在 View 里通过 `Task { await viewModel.xxx() }` 调用。
- action 执行成功后统一调用 `await loadCollections()` 刷新全量数据，确保界面与数据库一致，不手动在内存中增删条目。
- `self.error = error as? AppError`：UseCase 抛出的都是 `AppError`，`as?` 转型成功；如果将来有其他错误类型漏出，`as?` 返回 `nil`，可视需要改为 `(error as? AppError) ?? .unknown(error)` 兜底。
- `defer { isLoading = false }` 保证不论成功还是失败，`isLoading` 都会被重置。
- `renamingCollectionID` 决定当前正在重命名哪个 Collection，View 据此控制 Sheet 是否打开，并预填 `renameTitle`。

---

## M2-10 CollectionListScreen

**文件：** `Features/Collections/Views/CollectionListScreen.swift`

```swift
import SwiftUI

struct CollectionListScreen: View {

    @StateObject private var viewModel: CollectionListViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var editMode: EditMode = .inactive

    init(repository: CollectionRepositoryProtocol) {
        _viewModel = StateObject(
            wrappedValue: CollectionListViewModel(repository: repository)
        )
    }

    var body: some View {
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
        .navigationTitle("我的收藏")
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
            CollectionCreateSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.renamingCollectionID != nil },
            set: { if !$0 { viewModel.renamingCollectionID = nil } }
        )) {
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
        .task {
            await viewModel.loadCollections()
        }
    }

    private var collectionList: some View {
        List {
            ForEach(viewModel.collections) { collection in
                CollectionCard(collection: collection)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard editMode == .inactive else { return }
                        router.navigate(to: .pageList(collectionID: collection.id))
                    }
                    .contextMenu {
                        CollectionContextMenu(
                            collection: collection,
                            onRename: {
                                viewModel.renamingCollectionID = collection.id
                                viewModel.renameTitle = collection.title
                            },
                            onPin: {
                                Task { await viewModel.pinCollection(id: collection.id) }
                            },
                            onDelete: {
                                Task { await viewModel.deleteCollection(id: collection.id) }
                            }
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteCollection(id: collection.id) }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onMove { from, to in
                guard let sourceIndex = from.first else { return }
                let movingID = viewModel.collections[sourceIndex].id
                let targetID: UUID? = to > 0
                    ? viewModel.collections[min(to - 1, viewModel.collections.count - 1)].id
                    : nil
                Task {
                    await viewModel.reorderCollection(moving: movingID, after: targetID)
                }
            }
        }
        .listStyle(.plain)
        .background(ColorTokens.backgroundPrimary)
    }
}

#Preview {
    NavigationStack {
        Text("CollectionListScreen Preview")
    }
}
```

**Git commit message：**

```
feat: build CollectionListScreen with list and EditMode
```

**解释：**

- `_viewModel = StateObject(wrappedValue: CollectionListViewModel(repository: repository))` 是需要在 `init` 里向 ViewModel 传参时的标准写法，直接在属性声明处赋值会导致每次 View 重建都创建新实例。
- `@EnvironmentObject private var router: AppRouter` 由 M1 的 `RootView` 注入，`CollectionListScreen` 不需要自己创建。
- `@State private var editMode: EditMode = .inactive` 配合 `.environment(\.editMode, $editMode)` 和 `EditButton()` 实现拖动排序模式。`editMode` 是纯 UI 状态，不进 ViewModel。
- `guard editMode == .inactive else { return }` 防止编辑模式下点击行触发导航跳转。
- `.task { await viewModel.loadCollections() }` 在 View 出现时异步加载，View 消失时系统自动取消任务，比 `.onAppear` + `Task { }` 更安全。
- `CollectionContextMenu` 通过三个闭包接收回调，不直接持有 viewModel，View 负责把 viewModel 的异步方法包装成闭包传入。
- `.onMove` 中 `to` 是插入位置，`to - 1` 才是要排在其后的元素 index。`min(to - 1, collections.count - 1)` 防止越界。
- `Task { await viewModel.xxx() }` 是在同步的 SwiftUI 事件回调（`.onTapGesture`、`swipeActions`、`.onMove`）里启动异步任务的标准写法。

---

## M2-11 CollectionCard

**文件：** `Features/Collections/Views/CollectionCard.swift`

```swift
import SwiftUI

struct CollectionCard: View {
    let collection: Collection

    var body: some View {
        HStack(spacing: SpacingTokens.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: collection.iconName ?? "folder.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                HStack(spacing: SpacingTokens.xs) {
                    Text(collection.title)
                        .font(TypographyTokens.title)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(1)
                    if collection.isPinned {
                        CollectionPinnedIndicator()
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.sm)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.xs)
    }

    private var accentColor: Color {
        if let token = collection.colorToken {
            return Color(token)
        }
        return ColorTokens.accent
    }
}

#Preview {
    CollectionCard(collection: Collection(
        id: UUID(),
        title: "示例 Collection",
        createdAt: Date(),
        updatedAt: Date(),
        sortIndex: 1000,
        isPinned: true
    ))
    .padding()
}
```

**Git commit message：**

```
feat: build CollectionCard component
```

**解释：**

- `let collection: Collection` 用 `let`，卡片是只读展示组件，不持有可变状态。
- `accentColor` 是私有计算属性，封装 `colorToken` → `Color` 的转换，没有设置颜色时回退到主题 accent 色。
- `lineLimit(1)` 防止超长标题撑开卡片高度。
- 所有间距用 `SpacingTokens` 常量，不写魔法数字。

---

## M2-12 CollectionEmptyState

**文件：** `Features/Collections/Views/CollectionEmptyState.swift`

```swift
import SwiftUI

struct CollectionEmptyState: View {
    let onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(spacing: SpacingTokens.sm) {
                Text("还没有收藏")
                    .font(TypographyTokens.title)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("点击下方按钮创建第一个收藏")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateTapped) {
                Label("新建收藏", systemImage: "plus")
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
    CollectionEmptyState(onCreateTapped: {})
}
```

**Git commit message：**

```
feat: build CollectionEmptyState component
```

**解释：**

- `onCreateTapped: () -> Void` 是回调闭包。空状态 View 不持有 ViewModel，只通知父级有创建意图，保持组件可独立复用和预览。
- 上下各一个 `Spacer()` 让内容在垂直方向居中。

---

## M2-13 CollectionCreateSheet

**文件：** `Features/Collections/Views/CollectionCreateSheet.swift`

```swift
import SwiftUI

struct CollectionCreateSheet: View {

    @ObservedObject var viewModel: CollectionListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("收藏名称", text: $viewModel.newCollectionTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            Task { await viewModel.createCollection() }
                        }
                }
            }
            .navigationTitle("新建收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.newCollectionTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        Task { await viewModel.createCollection() }
                    }
                    .disabled(viewModel.newCollectionTitle.trimmingCharacters(in: .whitespaces).isEmpty)
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
feat: build CollectionCreateSheet
```

**解释：**

- `@ObservedObject var viewModel` 不用 `@StateObject`，Sheet 不持有 ViewModel 的生命周期，ViewModel 由 `CollectionListScreen` 持有。
- `Task { await viewModel.createCollection() }` 是在同步 Button action 回调里启动异步任务的标准写法。
- `@FocusState` 控制键盘焦点，Sheet 出现时自动弹出键盘，减少用户点击步骤。
- `.presentationDetents([.height(220)])` 让 Sheet 以小面板形式出现，符合"轻量创建"的交互意图。
- 创建成功后 `createCollection()` 内部会把 `isShowingCreateSheet` 置为 false，Sheet 自动关闭。取消时手动调用 `dismiss()` 并清空标题。

---

## M2-14 CollectionRenameSheet

**文件：** `Features/Collections/Views/CollectionRenameSheet.swift`

```swift
import SwiftUI

struct CollectionRenameSheet: View {

    @ObservedObject var viewModel: CollectionListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("收藏名称", text: $viewModel.renameTitle)
                        .focused($isTitleFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            guard let id = viewModel.renamingCollectionID else { return }
                            Task { await viewModel.renameCollection(id: id) }
                        }
                }
            }
            .navigationTitle("重命名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.renamingCollectionID = nil
                        viewModel.renameTitle = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        guard let id = viewModel.renamingCollectionID else { return }
                        Task { await viewModel.renameCollection(id: id) }
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
feat: build CollectionRenameSheet
```

**解释：**

- 与 `CollectionCreateSheet` 结构一致，区别是绑定 `viewModel.renameTitle` 并调用 `renameCollection(id:)`。
- `guard let id = viewModel.renamingCollectionID` 安全解包，确保 id 存在才调用。
- 取消时同时清空 `renamingCollectionID` 和 `renameTitle`，确保 ViewModel 状态干净，下次打开时不残留旧值。
- `CollectionListScreen` 里 Sheet 是否打开由 `Binding(get: { viewModel.renamingCollectionID != nil }, ...)` 控制，`renamingCollectionID` 置 nil 就会自动关闭 Sheet。

---

## M2-15 CollectionDeleteDialog

**文件：** `Features/Collections/Views/CollectionDeleteDialog.swift`

```swift
import SwiftUI

struct CollectionDeleteDialog: View {

    let collectionID: UUID
    @ObservedObject var viewModel: CollectionListViewModel

    var body: some View {
        Group {
            Button("删除", role: .destructive) {
                Task { await viewModel.deleteCollection(id: collectionID) }
            }
            Button("取消", role: .cancel) { }
        }
    }
}
```

**Git commit message：**

```
feat: build CollectionDeleteDialog
```

**解释：**

- `CollectionDeleteDialog` 只提供 Alert 的按钮内容，被嵌入调用方的 `.alert` 修饰器中使用。
- `Button("删除", role: .destructive)` 让系统自动把按钮渲染为红色，明确传达破坏性操作的视觉信号。
- 删除操作需要 `Task { await ... }` 包裹，因为 `deleteCollection` 是 `async` 方法。

---

## M2-16 CollectionContextMenu

**文件：** `Features/Collections/Views/CollectionContextMenu.swift`

```swift
import SwiftUI

struct CollectionContextMenu: View {
    let collection: Collection
    let onRename: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            Button(action: onRename) {
                Label("重命名", systemImage: "pencil")
            }

            Button(action: onPin) {
                Label(
                    collection.isPinned ? "取消固定" : "固定",
                    systemImage: collection.isPinned ? "pin.slash" : "pin"
                )
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
feat: build CollectionContextMenu
```

**解释：**

- 通过三个闭包 `onRename`、`onPin`、`onDelete` 接收回调，不持有 viewModel，职责单一，可独立复用和测试。
- 调用方（`CollectionListScreen`）负责把 viewModel 的异步方法包装成闭包传入：`onPin: { Task { await viewModel.pinCollection(id: collection.id) } }`。
- 固定按钮的文案和图标根据 `collection.isPinned` 动态切换，让用户清楚知道点击后会发生什么。
- `Divider()` 在视觉上将破坏性操作与普通操作隔开。

---

## M2-17 CollectionPinnedIndicator

**文件：** `Features/Collections/Views/CollectionPinnedIndicator.swift`

```swift
import SwiftUI

struct CollectionPinnedIndicator: View {
    var body: some View {
        Image(systemName: "pin.fill")
            .font(.caption2)
            .foregroundStyle(ColorTokens.accent)
    }
}

#Preview {
    CollectionPinnedIndicator()
        .padding()
}
```

**Git commit message：**

```
feat: build CollectionPinnedIndicator
```

**解释：** 固定标记是一个极简的图钉图标，使用主题 accent 色，让用户一眼识别哪些 Collection 被固定。拆成独立 View 方便在卡片和其他位置复用。

---

## M2-18 AppError 补充 validationFailure

**文件：** `Infrastructure/AppError.swift`（在 M1 基础上新增一个 case）

```swift
import Foundation

enum AppError: LocalizedError {
    case repositoryError(RepositoryError)
    case validationFailure(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .repositoryError(let e):
            return "数据操作失败：\(e)"
        case .validationFailure(let message):
            return message
        case .unknown(let e):
            return "未知错误：\(e.localizedDescription)"
        }
    }
}
```

**Git commit message：**

```
feat: add validationFailure case to AppError
```

**解释：**

- M1 的 `AppError` 只有 `repositoryError` 和 `unknown` 两个 case。M2 新增 `validationFailure(String)`，关联一个用户可读的描述字符串，为后续在 UseCase 层做业务校验时预留接口（如标题为空时抛出）。
- M2 阶段标题的空字符串检查在 ViewModel 里用 `guard` 做，不抛错误，`validationFailure` 暂时没有被实际调用。
- 本文件在 M1 已建立，此处只新增一个 case 和对应的 `errorDescription` 分支，不改动 `repositoryError` 和 `unknown`。

---

## M2-19 CollectionRepository 完整实现

**文件：** `Data/Repositories/CollectionRepository.swift`（在 M1 骨架基础上完整实现，方法签名同步改为 `async throws`）

```swift
import Foundation
import SwiftData

class CollectionRepository: CollectionRepositoryProtocol {

    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [Collection] {
        let descriptor = FetchDescriptor<CollectionModel>(
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        do {
            let models = try context.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func fetch(by id: UUID) async throws -> Collection? {
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.id == id }
        )
        do {
            return try context.fetch(descriptor).first?.toDomain()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func create(_ collection: Collection) async throws {
        let model = CollectionModel(
            id: collection.id,
            title: collection.title,
            iconName: collection.iconName,
            colorToken: collection.colorToken,
            createdAt: collection.createdAt,
            updatedAt: collection.updatedAt,
            sortIndex: collection.sortIndex,
            isPinned: collection.isPinned
        )
        context.insert(model)
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func update(_ collection: Collection) async throws {
        let descriptor = FetchDescriptor<CollectionModel>(
            predicate: #Predicate { $0.id == collection.id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.title = collection.title
        model.iconName = collection.iconName
        model.colorToken = collection.colorToken
        model.updatedAt = collection.updatedAt
        model.sortIndex = collection.sortIndex
        model.isPinned = collection.isPinned
        do {
            try context.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<CollectionModel>(
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
feat: implement CollectionRepository CRUD
```

**解释：**

- 方法签名改为 `async throws` 以匹配升级后的 `CollectionRepositoryProtocol`。SwiftData 的 `context.fetch` 和 `context.save` 本身是同步的，`async` 关键字让 Repository 可以在 `async` 上下文中被 `await` 调用。
- `FetchDescriptor` 是 SwiftData 的查询描述符，`predicate` 提供过滤条件，`sortBy` 提供排序。
- `#Predicate { $0.id == id }` 是 SwiftData 的 macro，编译期检查 predicate 语法。
- `context.fetch(descriptor).first` 对于 by-id 查询取第一条即可，`id` 字段有 `@Attribute(.unique)` 保证唯一。
- 所有写操作后都调用 `context.save()`，SwiftData 不会自动持久化，必须显式保存。
- `update` 里直接修改 `model` 的属性，SwiftData 追踪这些变更，`save` 时一并写入。

---

## M2-20 RootView 更新

**文件：** `App/RootView.swift`（在 M1-04 基础上替换根视图）

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
                    Text("Page List 占位 \(collectionID)")   // M3 替换
                case .nodeEditor(let pageID):
                    Text("Node Editor 占位 \(pageID)")       // M4 替换
                }
            }
        }
        .environmentObject(router)
    }
}
```

**Git commit message：**

```
feat: replace RootView placeholder with CollectionListScreen
```

**解释：**

- `@EnvironmentObject private var dependencyContainer: DependencyContainer` 由 M1 的 `NotteApp` 注入（`.environmentObject(dependency)`），`RootView` 直接取用，不需要自己创建。
- `dependencyContainer.collectionRepository` 取出 Repository 传给 `CollectionListScreen`，ViewModel 从这里获得依赖。
- `navigationDestination` 里两个占位 Text 在 M3、M4 分别替换为真正的 View，结构不需要再动。

---

## M2-21~26 单元测试

### `Tests/UnitTests/Mocks/MockCollectionRepository.swift`

```swift
import Foundation
@testable import Notte

actor MockCollectionRepository: CollectionRepositoryProtocol {

    var storedCollections: [Collection] = []
    var shouldThrowOnCreate = false

    func fetchAll() async throws -> [Collection] {
        storedCollections
    }

    func fetch(by id: UUID) async throws -> Collection? {
        storedCollections.first { $0.id == id }
    }

    func create(_ collection: Collection) async throws {
        if shouldThrowOnCreate { throw RepositoryError.saveFailed(NSError()) }
        storedCollections.append(collection)
    }

    func update(_ collection: Collection) async throws {
        guard let index = storedCollections.firstIndex(where: { $0.id == collection.id }) else {
            throw RepositoryError.notFound
        }
        storedCollections[index] = collection
    }

    func delete(by id: UUID) async throws {
        guard let index = storedCollections.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        storedCollections.remove(at: index)
    }
}
```

---

### `Tests/UnitTests/CollectionRepositoryTests.swift`

```swift
import XCTest
import SwiftData
@testable import Notte

@MainActor
final class CollectionRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var repository: CollectionRepository!

    override func setUp() async throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
        repository = CollectionRepository(context: context)
    }

    func test_fetchAll_whenEmpty_returnsEmptyArray() async throws {
        let result = try await repository.fetchAll()
        XCTAssertTrue(result.isEmpty)
    }

    func test_create_withValidCollection_persistsSuccessfully() async throws {
        let collection = makeCollection(title: "测试")
        try await repository.create(collection)

        let result = try await repository.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "测试")
    }

    func test_fetch_byExistingID_returnsCollection() async throws {
        let collection = makeCollection(title: "查找测试")
        try await repository.create(collection)

        let found = try await repository.fetch(by: collection.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "查找测试")
    }

    func test_update_existingCollection_updatesTitle() async throws {
        var collection = makeCollection(title: "旧标题")
        try await repository.create(collection)
        collection.title = "新标题"
        try await repository.update(collection)

        let updated = try await repository.fetch(by: collection.id)
        XCTAssertEqual(updated?.title, "新标题")
    }

    func test_delete_existingCollection_removesFromStore() async throws {
        let collection = makeCollection(title: "待删除")
        try await repository.create(collection)
        try await repository.delete(by: collection.id)

        let result = try await repository.fetchAll()
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

    private func makeCollection(title: String, sortIndex: Double = 1000) -> Collection {
        Collection(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: sortIndex,
            isPinned: false
        )
    }
}
```

**Git commit message：**

```
test: add CollectionRepository unit tests
```

---

### `Tests/UnitTests/CreateCollectionUseCaseTests.swift`

```swift
import XCTest
@testable import Notte

final class CreateCollectionUseCaseTests: XCTestCase {

    var repository: MockCollectionRepository!
    var useCase: CreateCollectionUseCase!

    override func setUp() {
        repository = MockCollectionRepository()
        useCase = CreateCollectionUseCase(repository: repository)
    }

    func test_execute_withValidTitle_returnsCollection() async throws {
        let result = try await useCase.execute(title: "新建")
        XCTAssertEqual(result.title, "新建")
    }

    func test_execute_assignsIncrementingSortIndex() async throws {
        let first = try await useCase.execute(title: "第一")
        let second = try await useCase.execute(title: "第二")
        XCTAssertGreaterThan(second.sortIndex, first.sortIndex)
    }

    func test_execute_whenRepositoryThrows_propagatesError() async {
        await repository.setShouldThrow(true)
        do {
            _ = try await useCase.execute(title: "失败测试")
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
```

**Git commit message：**

```
test: add CreateCollectionUseCase unit tests
```

**解释：**

- `MockCollectionRepository` 声明为 `actor` 以匹配 `async throws` 的并发要求，用内存数组模拟数据库，UseCase 测试完全不依赖 SwiftData。
- 测试方法都是 `async throws`，对应 UseCase 和 Repository 的 `async throws` 签名。
- Mock 放在 `Tests/UnitTests/Mocks/` 目录，M3、M4 的 Mock 也放这里统一管理。

---

## 目录结构速览

M2 新增与修改的文件一览：

```
Notte/
├── App/
│   └── RootView.swift                               ← 更新：替换为 CollectionListScreen
│
├── Features/
│   └── Collections/                                 ← 新增整个模块
│       ├── UseCases/
│       │   ├── FetchCollectionsUseCase.swift
│       │   ├── CreateCollectionUseCase.swift
│       │   ├── RenameCollectionUseCase.swift
│       │   ├── DeleteCollectionUseCase.swift
│       │   ├── PinCollectionUseCase.swift
│       │   └── ReorderCollectionsUseCase.swift
│       ├── ViewModels/
│       │   └── CollectionListViewModel.swift
│       └── Views/
│           ├── CollectionListScreen.swift
│           ├── CollectionCard.swift
│           ├── CollectionEmptyState.swift
│           ├── CollectionCreateSheet.swift
│           ├── CollectionRenameSheet.swift
│           ├── CollectionDeleteDialog.swift
│           ├── CollectionContextMenu.swift
│           └── CollectionPinnedIndicator.swift
│
├── Domain/
│   └── Protocols/
│       └── CollectionRepositoryProtocol.swift       ← 更新：方法签名改为 async throws
│
├── Data/
│   └── Repositories/
│       └── CollectionRepository.swift               ← 更新：骨架 → 完整实现，async throws
│
├── Shared/
│   └── Utilities/
│       └── SortIndexNormalizer.swift                ← 新增
│
└── Infrastructure/
    └── AppError.swift                               ← 更新：新增 validationFailure case

Tests/
└── UnitTests/
    ├── CollectionRepositoryTests.swift
    ├── CreateCollectionUseCaseTests.swift
    ├── RenameCollectionUseCaseTests.swift           ← 结构与 Create 测试类似，略
    ├── DeleteCollectionUseCaseTests.swift
    ├── ReorderCollectionsUseCaseTests.swift         ← 验证 sortIndex 插入逻辑
    ├── CollectionListViewModelTests.swift           ← 验证状态更新逻辑
    └── Mocks/
        └── MockCollectionRepository.swift
```

---

> M2 Collections 全部完成。验收条件：首页显示 Collection 列表，增删改查、固定、排序全部成立，排序结果重启后保留，空状态清晰引导创建，10 条以上无卡顿，单元测试全部通过。
