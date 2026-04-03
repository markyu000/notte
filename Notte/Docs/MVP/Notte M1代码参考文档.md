# Notte M1 代码参考文档

> 本文档包含 M1（Foundation）阶段所有 issue 的文件路径、代码内容与解释。

---

## 目录

1. [M1-02 App 入口](#m1-02-app-入口)
2. [M1-03 AppBootstrap](#m1-03-appbootstrap)
3. [M1-04 AppRouter](#m1-04-approuter)
4. [M1-05 DependencyContainer](#m1-05-dependencycontainer)
5. [M1-06 Collection Domain Entity](#m1-06-collection-domain-entity)
6. [M1-07 Page Domain Entity](#m1-07-page-domain-entity)
7. [M1-08 Node Domain Entity](#m1-08-node-domain-entity)
8. [M1-09/10 Block Domain Entity & BlockType](#m1-0910-block-domain-entity--blocktype)
9. [M1-11~14 SwiftData Models](#m1-1114-swiftdata-models)
10. [M1-15 SortIndexPolicy](#m1-15-sortindexpolicy)
11. [M1-16 PersistenceController](#m1-16-persistencecontroller)
12. [M1-17 MigrationPlan](#m1-17-migrationplan)
13. [M1-18~21 Repository Protocols](#m1-1821-repository-protocols)
14. [M1-22~25 Repository Skeletons](#m1-2225-repository-skeletons)
15. [M1-26~28 Theme Tokens](#m1-2628-theme-tokens)
16. [M1-29 AppLogger](#m1-29-applogger)
17. [M1-30 AppError & AppErrorPresenter](#m1-30-apperror--apperrorpresenter)
18. [M1-31 DebugMenuView](#m1-31-debugmenuview)
19. [M1-32~33 Tests](#m1-3233-tests)

---

## M1-02 App 入口

### `App/NotteApp.swift`

```swift
import SwiftUI

@main
struct NotteApp: App {

    @StateObject private var appBootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            if appBootstrap.isReady,
               let container = appBootstrap.modelContainer,
               let dependency = appBootstrap.dependencyContainer {
                RootView()
                    .environmentObject(appBootstrap)
                    .environmentObject(dependency)
                    .modelContainer(container)
            } else {
                ProgressView("启动中...")
            }
        }
    }
}
```

**解释：**
- `@main` 标记整个程序的入口，全局只能有一个。
- `@StateObject` 让 AppBootstrap 的生命周期由 NotteApp 持有，不会因 SwiftUI 重新渲染而销毁。
- `appBootstrap.isReady` 控制显示启动画面还是正式界面。
- `.modelContainer()` 挂在 RootView 上而不是 WindowGroup 上，配合可选绑定确保只有在 container 初始化完成后才挂载，避免异步初始化期间的 nil 问题。
- `let container` 和 `let dependency` 用可选绑定而不是强制解包，安全地解包异步初始化完成后的值。

---

### `App/RootView.swift`

```swift
struct RootView: View {
    var body: some View {
        Text("Notte")  // M2 替换为 CollectionListView
    }
}
```

**解释：** M1 阶段的占位根视图，M2 完成后替换为 CollectionListView。

---

### `App/DependencyContainer.swift`（占位）

```swift
@MainActor
class DependencyContainer: ObservableObject {
    // M1-05 填充
}
```

---

## M1-03 AppBootstrap

### `App/AppBootstrap.swift`

```swift
import Foundation
import SwiftData

@MainActor
class AppBootstrap: ObservableObject {

    @Published var isReady: Bool = false
    private(set) var modelContainer: ModelContainer?
    private(set) var dependencyContainer: DependencyContainer?

    init() {
        Task {
            await setup()
        }
    }

    private func setup() async {
        do {
            let container = try PersistenceController.makeContainer()
            modelContainer = container
            dependencyContainer = DependencyContainer(modelContainer: container)
            isReady = true
        } catch {
            fatalError("SwiftData 初始化失败：\(error)")
        }
    }
}
```

**解释：**
- `@MainActor` 保证所有操作在主线程，因为 `isReady` 的变化会驱动 UI 更新。
- `@Published var isReady` 变成 true 时，NotteApp 收到通知，切换显示 RootView。
- `modelContainer` 和 `dependencyContainer` 都是可选类型，异步初始化完成前是 nil。
- `Task { await setup() }` 在 init 里启动异步任务，Swift 的 init 本身不能是 async，用 Task 包裹绕开这个限制。
- `private(set)` 让外部只能读，只有 AppBootstrap 自己能写。
- `fatalError` 在初始化失败时让 App 崩溃并打印原因，MVP 阶段这是合理的选择。

---

## M1-04 AppRouter

### `App/AppRouter.swift`

```swift
import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case pageList(collectionID: UUID)
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

**解释：**
- `AppRoute` 枚举定义所有导航目的地。MVP 主路径只有两个跳转目标：PageList 和 NodeEditor。CollectionList 是根页面，永远是起点，不需要出现在枚举里。
- `Hashable` 是 NavigationStack 的要求，每个目的地必须可哈希才能被追踪。
- `path` 是导航栈，空数组表示在根页面，每往里跳一层就 append 一个 AppRoute。
- `navigate`、`goBack`、`goRoot` 是三个基本导航动作。

---

### `App/RootView.swift`（更新）

```swift
import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            Text("Collection List 占位")
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .pageList(let collectionID):
                        Text("Page List 占位 \(collectionID)")
                    case .nodeEditor(let pageID):
                        Text("Node Editor 占位 \(pageID)")
                    }
                }
        }
        .environmentObject(router)
    }
}
```

**解释：**
- `NavigationStack(path: $router.path)` 把导航栈控制权交给 AppRouter，`$` 表示双向绑定。
- `.navigationDestination(for: AppRoute.self)` 告诉 NavigationStack 当 path 里出现 AppRoute 时，用 switch 决定显示哪个 View。
- `.environmentObject(router)` 把 AppRouter 注入环境，任何子 View 都能取到 router 并触发跳转。

---

## M1-05 DependencyContainer

### `App/DependencyContainer.swift`

```swift
import Foundation
import SwiftData

@MainActor
class DependencyContainer: ObservableObject {

    let collectionRepository: CollectionRepositoryProtocol
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

**解释：**
- `ModelContext(modelContainer)` 从 ModelContainer 派生出一个 Context，所有数据读写都通过它。
- Repository 的类型声明为 Protocol 而不是具体实现类，方便测试时替换 Mock。
- 所有 Repository 集中在这里创建，ViewModel 通过 `@EnvironmentObject` 取到 DependencyContainer 后直接访问对应的 Repository。

---

## M1-06 Collection Domain Entity

### `Domain/Entities/Collection.swift`

```swift
import Foundation

struct Collection: Identifiable, Hashable {
    let id: UUID
    var title: String
    var iconName: String?
    var colorToken: String?
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isPinned: Bool
}
```

**解释：**
- `id` 用 `let`，创建后永远不变。
- `iconName` 和 `colorToken` 用 `?`，用户可以不设置图标和颜色。
- `sortIndex` 用 Double，支持在两个条目之间插入时取中间值，不需要重排整个列表。
- `isPinned` 表示是否固定在列表顶部。
- `Identifiable` 让 SwiftUI 的 List 和 ForEach 能追踪每个条目。
- `Hashable` 让 Collection 可以用于 NavigationStack 导航传参。

---

## M1-07 Page Domain Entity

### `Domain/Entities/Page.swift`

```swift
import Foundation

struct Page: Identifiable, Hashable {
    let id: UUID
    let collectionID: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isArchived: Bool
}
```

**解释：**
- `collectionID` 用 `let`，Page 创建后所属的 Collection 不能改变。
- `isArchived` 是归档标记，归档的 Page 不出现在正常列表里但数据还在。Page 没有 `iconName` 和 `colorToken`，这些个性化属性只在 Collection 层面有。

---

## M1-08 Node Domain Entity

### `Domain/Entities/Node.swift`

```swift
import Foundation

struct Node: Identifiable, Hashable {
    let id: UUID
    let pageID: UUID
    var parentNodeID: UUID?
    var title: String
    var depth: Int
    var sortIndex: Double
    var isCollapsed: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

**解释：**
- `parentNodeID` 记录父节点的 id，nil 表示在最顶层。用 id 引用而不是直接嵌套 Node 对象，因为 SwiftData 采用扁平存储策略，运行时再根据 parentNodeID 重建树结构。
- `depth` 同时承担两个职责：视觉缩进层级（depth 0 是最顶层）和标题渲染级别（depth 0 渲染 h1，depth 1 渲染 h2，以此类推到 depth 5 渲染 h6，超过 5 维持 h6）。
- `isCollapsed` 记录折叠状态，折叠后子节点在 UI 上隐藏但数据还在。

---

## M1-09/10 Block Domain Entity & BlockType

### `Domain/Entities/BlockType.swift`

```swift
import Foundation

enum BlockType: String, Codable, Hashable {
    case text
    // POST-MVP:
    // case bullet
    // case image
    // case code
    // case quote
}
```

**解释：**
- `String` 让枚举的原始值是字符串，SwiftData 存储时存这个字符串，将来加新 case 不会破坏已有数据。
- `Codable` 让 BlockType 可以被序列化和反序列化。
- 注释掉的 case 是 Post-MVP 的扩展点。

---

### `Domain/Entities/Block.swift`

```swift
import Foundation

struct Block: Identifiable, Hashable {
    let id: UUID
    let nodeID: UUID
    var type: BlockType
    var content: String
    var sortIndex: Double
    var createdAt: Date
    var updatedAt: Date
}
```

**解释：**
- `nodeID` 用 `let`，Block 创建后所属的 Node 不能改变。
- `type` 是 BlockType 枚举，MVP 阶段永远是 `.text`。
- `content` 对 text 类型是用户输入的文字，Post-MVP 阶段 image 类型存文件路径，code 类型存代码字符串，复用同一个字段。
- Block 没有 `title`，标题在 Node 层面，Block 只存内容。

---

## M1-11~14 SwiftData Models

### `Data/Models/CollectionModel.swift`

```swift
import Foundation
import SwiftData

@Model
class CollectionModel {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var iconName: String? = nil
    var colorToken: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortIndex: Double = 0
    var isPinned: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        iconName: String? = nil,
        colorToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortIndex: Double = 0,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.colorToken = colorToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortIndex = sortIndex
        self.isPinned = isPinned
    }
}

extension CollectionModel {
    func toDomain() -> Collection {
        Collection(
            id: id,
            title: title,
            iconName: iconName,
            colorToken: colorToken,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortIndex: sortIndex,
            isPinned: isPinned
        )
    }
}
```

**解释：**
- `@Attribute(.unique)` 让 SwiftData 在数据库层面强制保证 id 唯一，同时建立索引提升查询性能。
- 所有属性都有默认值，SwiftData 的要求。
- init 里 `title` 强制传入，其余都有默认值，创建时只需要传 `title` 就够了。
- `toDomain()` 把 @Model 类转换成 Domain Entity，Repository 在读取数据时调用。

---

### `Data/Models/PageModel.swift`

```swift
import Foundation
import SwiftData

@Model
class PageModel {
    @Attribute(.unique) var id: UUID = UUID()
    var collectionID: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortIndex: Double = 0
    var isArchived: Bool = false

    init(
        id: UUID = UUID(),
        collectionID: UUID,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortIndex: Double = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.collectionID = collectionID
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortIndex = sortIndex
        self.isArchived = isArchived
    }
}

extension PageModel {
    func toDomain() -> Page {
        Page(
            id: id,
            collectionID: collectionID,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortIndex: sortIndex,
            isArchived: isArchived
        )
    }
}
```

---

### `Data/Models/NodeModel.swift`

```swift
import Foundation
import SwiftData

@Model
class NodeModel {
    @Attribute(.unique) var id: UUID = UUID()
    var pageID: UUID = UUID()
    var parentNodeID: UUID? = nil
    var title: String = ""
    var depth: Int = 0
    var sortIndex: Double = 0
    var isCollapsed: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        pageID: UUID,
        parentNodeID: UUID? = nil,
        title: String,
        depth: Int = 0,
        sortIndex: Double = 0,
        isCollapsed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.pageID = pageID
        self.parentNodeID = parentNodeID
        self.title = title
        self.depth = depth
        self.sortIndex = sortIndex
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension NodeModel {
    func toDomain() -> Node {
        Node(
            id: id,
            pageID: pageID,
            parentNodeID: parentNodeID,
            title: title,
            depth: depth,
            sortIndex: sortIndex,
            isCollapsed: isCollapsed,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

---

### `Data/Models/BlockModel.swift`

```swift
import Foundation
import SwiftData

@Model
class BlockModel {
    @Attribute(.unique) var id: UUID = UUID()
    var nodeID: UUID = UUID()
    var type: String = BlockType.text.rawValue
    var content: String = ""
    var sortIndex: Double = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        nodeID: UUID,
        type: String = BlockType.text.rawValue,
        content: String = "",
        sortIndex: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.nodeID = nodeID
        self.type = type
        self.content = content
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension BlockModel {
    func toDomain() -> Block {
        Block(
            id: id,
            nodeID: nodeID,
            type: BlockType(rawValue: type) ?? .text,
            content: content,
            sortIndex: sortIndex,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

**解释：**
- `type` 在 BlockModel 里存 String 而不是 BlockType 枚举，避免 SwiftData 对自定义枚举的兼容性问题。
- `toDomain()` 里用 `BlockType(rawValue: type) ?? .text` 把 String 转回枚举，找不到对应值时默认 `.text`。

---

## M1-15 SortIndexPolicy

### `Shared/Utilities/SortIndexPolicy.swift`

```swift
import Foundation

enum SortIndexPolicy {

    static let initialSpacing: Double = 1000
    static let minimumGap: Double = 0.001

    static func initialIndex() -> Double {
        initialSpacing
    }

    static func indexAfter(last: Double) -> Double {
        last + initialSpacing
    }

    static func indexBetween(before: Double, after: Double) -> Double {
        (before + after) / 2
    }

    static func needsNormalization(before: Double, after: Double) -> Bool {
        (after - before) < minimumGap
    }

    static func normalize(count: Int) -> [Double] {
        (1...count).map { Double($0) * initialSpacing }
    }
}
```

**解释：**
- `initialSpacing` 是初始间隔，新列表第一个条目 index 是 1000，第二个是 2000。
- `indexBetween` 是最常用的方法，在两个条目中间插入时取中间值，不需要重排其他条目。
- `needsNormalization` 检查相邻 index 差值是否小于最小间隔，是则需要重新归一化。
- `normalize` 重新给整个列表分配 index，从 1000 开始每隔 1000 一个。

---

## M1-16 PersistenceController

### `Data/Persistence/PersistenceController.swift`

```swift
import Foundation
import SwiftData

struct PersistenceController {

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: NotteMigrationPlan.self,
            configurations: config
        )
    }
}
```

**解释：**
- `static func` 不需要创建实例，直接调用 `PersistenceController.makeContainer()` 就行。
- `inMemory: Bool = false` 默认写入磁盘，测试时传 true 得到内存数据库，每次重启数据清空。
- `throws` 表示可能失败，调用方需要 `try` 处理。
- 接入 MigrationPlan 让 SwiftData 知道用哪个迁移计划处理版本升级。

---

## M1-17 MigrationPlan

### `Data/Persistence/MigrationPlan.swift`

```swift
import Foundation
import SwiftData

enum NotteMigrationPlan: SchemaMigrationPlan {

    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            CollectionModel.self,
            PageModel.self,
            NodeModel.self,
            BlockModel.self
        ]
    }
}
```

**解释：**
- `SchemaMigrationPlan` 是 SwiftData 提供的协议，告诉 SwiftData 用这个迁移计划处理版本升级。
- `schemas` 列出所有历史版本，将来加 V2 时在这里追加。
- `stages` 是版本间的迁移步骤，V1 是第一版所以是空数组。
- `versionIdentifier` 用三位数字表示版本号，对应 major.minor.patch。

---

## M1-18~21 Repository Protocols

### `Domain/Protocols/CollectionRepositoryProtocol.swift`

```swift
import Foundation

protocol CollectionRepositoryProtocol {
    func fetchAll() throws -> [Collection]
    func fetch(by id: UUID) throws -> Collection?
    func create(_ collection: Collection) throws
    func update(_ collection: Collection) throws
    func delete(by id: UUID) throws
}
```

---

### `Domain/Protocols/PageRepositoryProtocol.swift`

```swift
import Foundation

protocol PageRepositoryProtocol {
    func fetchAll(in collectionID: UUID) throws -> [Page]
    func fetch(by id: UUID) throws -> Page?
    func create(_ page: Page) throws
    func update(_ page: Page) throws
    func delete(by id: UUID) throws
}
```

---

### `Domain/Protocols/NodeRepositoryProtocol.swift`

```swift
import Foundation

protocol NodeRepositoryProtocol {
    func fetchAll(in pageID: UUID) throws -> [Node]
    func fetch(by id: UUID) throws -> Node?
    func create(_ node: Node) throws
    func update(_ node: Node) throws
    func delete(by id: UUID) throws
    func deleteAll(in pageID: UUID) throws
}
```

---

### `Domain/Protocols/BlockRepositoryProtocol.swift`

```swift
import Foundation

protocol BlockRepositoryProtocol {
    func fetchAll(in nodeID: UUID) throws -> [Block]
    func fetch(by id: UUID) throws -> Block?
    func create(_ block: Block) throws
    func update(_ block: Block) throws
    func delete(by id: UUID) throws
    func deleteAll(in nodeID: UUID) throws
}
```

**解释：**
- 四个 Protocol 定义了 Repository 层的接口契约，ViewModel 只依赖 Protocol，不依赖具体实现。
- Node 和 Block 多了 `deleteAll` 方法，因为删除 Page 时需要级联删除所有 Node，删除 Node 时需要级联删除所有 Block。
- Protocol 定义在 `Domain/Protocols/`，实现在 `Data/Repositories/`，通过 Protocol 隔离便于测试时替换 Mock。

---

## M1-22~25 Repository Skeletons

### `Domain/Enums/RepositoryError.swift`

```swift
import Foundation

enum RepositoryError: Error {
    case notImplemented
    case notFound
    case saveFailed(Error)
}
```

**解释：**
- `notImplemented` 是骨架阶段的占位错误，提醒开发者这个方法还没有真正实现。
- `notFound` 是按 id 查找时找不到对应记录时用的。
- `saveFailed` 是 SwiftData 写入失败时包装错误用的。

---

### `Data/Repositories/CollectionRepository.swift`

```swift
import Foundation
import SwiftData

class CollectionRepository: CollectionRepositoryProtocol {

    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Collection] {
        throw RepositoryError.notImplemented
    }

    func fetch(by id: UUID) throws -> Collection? {
        throw RepositoryError.notImplemented
    }

    func create(_ collection: Collection) throws {
        throw RepositoryError.notImplemented
    }

    func update(_ collection: Collection) throws {
        throw RepositoryError.notImplemented
    }

    func delete(by id: UUID) throws {
        throw RepositoryError.notImplemented
    }
}
```

**解释：** PageRepository、NodeRepository、BlockRepository 结构完全相同，方法签名对应各自的 Protocol。Node 和 Block 额外实现 `deleteAll` 方法。所有方法目前都抛出 `notImplemented`，真正的 CRUD 实现在 M2~M4 按需填充。

---

## M1-26~28 Theme Tokens

### `Shared/Theme/ColorTokens.swift`

```swift
import SwiftUI

struct ColorTokens {
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accent = Color("Accent")
    static let separator = Color("NotteSeparator")
}
```

**解释：** 所有颜色引用 Asset Catalog 里的 Color Set，支持 Light/Dark 自动切换。`separator` 对应的 Color Set 命名为 `NotteSeparator` 避免和 UIKit 内置的 `UIColor.separator` 冲突。

---

### `Shared/Theme/TypographyTokens.swift`

```swift
import SwiftUI

struct TypographyTokens {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title2, design: .rounded, weight: .semibold)
    static let body = Font.system(.body)
    static let caption = Font.system(.caption)

    static func nodeTitle(depth: Int) -> Font {
        switch depth {
        case 0: return Font.system(.title, design: .rounded, weight: .bold)
        case 1: return Font.system(.title2, design: .rounded, weight: .semibold)
        case 2: return Font.system(.title3, design: .rounded, weight: .semibold)
        case 3: return Font.system(.headline)
        case 4: return Font.system(.subheadline)
        default: return Font.system(.body)
        }
    }
}
```

**解释：**
- 基础 token 用于普通界面文字。
- `nodeTitle(depth:)` 根据 depth 返回对应字体，实现 h1-h6 的视觉效果，depth 超过 4 统一用 body。

---

### `Shared/Theme/SpacingTokens.swift`

```swift
import SwiftUI

struct SpacingTokens {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

**解释：** 所有 padding 和 spacing 都用这些常量，不写魔法数字。CGFloat 是 Apple 框架里表示图形尺寸的浮点数类型，SwiftUI 所有尺寸相关的参数都接收 CGFloat。

---

## M1-29 AppLogger

### `Infrastructure/Logging/AppLogger.swift`

```swift
import Foundation

protocol AppLogger {
    func debug(_ message: String, file: String, function: String)
    func info(_ message: String, file: String, function: String)
    func error(_ message: String, error: Error?, file: String, function: String)
}
```

---

### `Infrastructure/Logging/ConsoleLogger.swift`

```swift
import Foundation

struct ConsoleLogger: AppLogger {

    func debug(_ message: String, file: String = #file, function: String = #function) {
        #if DEBUG
        print("[DEBUG] \(file) \(function): \(message)")
        #endif
    }

    func info(_ message: String, file: String = #file, function: String = #function) {
        #if DEBUG
        print("[INFO] \(file) \(function): \(message)")
        #endif
    }

    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function) {
        #if DEBUG
        if let error = error {
            print("[ERROR] \(file) \(function): \(message) — \(error)")
        } else {
            print("[ERROR] \(file) \(function): \(message)")
        }
        #endif
    }
}
```

**解释：**
- `#if DEBUG` 只在 Debug 构建下编译这些代码，Release 构建里完全不存在，不影响性能。
- `file: String = #file` 和 `function: String = #function` 是 Swift 的特殊字面量，调用时自动填入当前文件名和函数名，方便定位日志来源。
- 用 Protocol 定义接口，将来可以换成第三方日志框架，不需要改调用方代码。

---

## M1-30 AppError & AppErrorPresenter

### `Infrastructure/AppError.swift`

```swift
import Foundation

enum AppError: LocalizedError {
    case repositoryError(RepositoryError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .repositoryError(let e):
            return "数据操作失败：\(e)"
        case .unknown(let e):
            return "未知错误：\(e.localizedDescription)"
        }
    }
}
```

**解释：**
- `LocalizedError` 是 Swift 标准库的协议，遵循它之后 SwiftUI 的 Alert 可以直接读取 `errorDescription` 来显示错误信息。
- ViewModel 里用 `@Published var error: AppError?` 持有错误状态，View 里用 `.alert` 监听并弹出提示。

---

### `Infrastructure/AppErrorPresenter.swift`

```swift
import Foundation

struct AppErrorPresenter {
    static func present(_ error: AppError, in viewModel: any ObservableObject) {
        // MVP 阶段占位，后续填充
    }
}
```

---

## M1-31 DebugMenuView

### `Infrastructure/Debug/DebugMenuView.swift`

```swift
import SwiftUI

#if DEBUG
struct DebugMenuView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section("数据") {
                    Button("清空所有数据", role: .destructive) {
                        clearAllData()
                    }
                }
            }
            .navigationTitle("调试菜单")
        }
    }

    private func clearAllData() {
        // M6 示例数据功能完成后填充
    }
}
#endif
```

**解释：**
- 整个文件包在 `#if DEBUG` 里，Release 构建完全不编译，不会出现在用户 App 里。
- `@Environment(\.modelContext)` 从 SwiftData 环境取 ModelContext，后续清空和填充示例数据的逻辑通过它操作。
- 入口在 M6 创建 SettingsView 时再加进去。

---

## M1-32~33 Tests

### `NotteTests/PersistenceControllerTests.swift`

```swift
import XCTest
import SwiftData
@testable import Notte

final class PersistenceControllerTests: XCTestCase {

    func testContainerInitializesSuccessfully() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        XCTAssertNotNil(container)
    }

    func testModelContextIsAvailable() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        XCTAssertNotNil(context)
    }
}
```

**解释：**
- `@testable import Notte` 让测试文件能访问 App target 里所有 internal 级别的类型。
- `inMemory: true` 让测试用内存数据库，不会在磁盘上留下测试数据。
- `testContainerInitializesSuccessfully` 验证 PersistenceController 能正常创建 ModelContainer。
- `testModelContextIsAvailable` 验证从 Container 派生 ModelContext 没有问题。

---

### `NotteTests/RepositoryProtocolTests.swift`

```swift
import XCTest
import SwiftData
@testable import Notte

@MainActor
final class RepositoryProtocolTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        container = try? PersistenceController.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    func testCollectionRepositoryConformsToProtocol() {
        let repo: any CollectionRepositoryProtocol = CollectionRepository(context: context)
        XCTAssertNotNil(repo)
    }

    func testPageRepositoryConformsToProtocol() {
        let repo: any PageRepositoryProtocol = PageRepository(context: context)
        XCTAssertNotNil(repo)
    }

    func testNodeRepositoryConformsToProtocol() {
        let repo: any NodeRepositoryProtocol = NodeRepository(context: context)
        XCTAssertNotNil(repo)
    }

    func testBlockRepositoryConformsToProtocol() {
        let repo: any BlockRepositoryProtocol = BlockRepository(context: context)
        XCTAssertNotNil(repo)
    }
}
```

**解释：**
- `@MainActor` 让整个测试类在主线程运行，因为 Repository 类声明了 `@MainActor`。
- `setUp` 在每个测试方法执行前运行，创建干净的内存数据库和 context。
- 每个测试把 Repository 声明为 Protocol 类型 `any XxxRepositoryProtocol`，如果 Repository 没有正确遵循 Protocol，编译就会直接报错，起到编译期验证的作用。

---

> M1 Foundation 全部完成。验收条件：工程可运行、SwiftData 正常初始化、四个 Repository skeleton 可调用、Theme Token 已定义、调试菜单文件已建好、测试全部通过。
