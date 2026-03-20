# Notte MVP 开发计划

Version: v1.0  
Tech Stack: SwiftUI + SwiftData + CloudKit  
Core Model: Collection → Page → Node → Block  
Target: iPhone（MVP 主平台）→ iPad → macOS

---

## 目录

1. [开发原则速览](#1-开发原则速览)
2. [整体阶段划分](#2-整体阶段划分)
3. [阶段详细计划](#3-阶段详细计划)
   - [阶段 0：MVP 范围冻结](#阶段-0mvp-范围冻结--定义锁定)
   - [阶段 1：工程底座](#阶段-1工程底座)
   - [阶段 2：Collection 模块](#阶段-2collection-模块)
   - [阶段 3：Page 模块](#阶段-3page-模块)
   - [阶段 4：Node Editor Core](#阶段-4node-editor-core)
   - [阶段 5：Node Editor UX](#阶段-5node-editor-ux-补齐)
   - [阶段 6：Onboarding、示例数据、设置页](#阶段-6onboarding示例数据设置页)
   - [阶段 7：iCloud Sync Beta](#阶段-7icloud-sync-beta)
   - [阶段 8：UI Polish、QA、封版发布](#阶段-8ui-polishqa封版发布)
4. [GitHub Project 完整配置方案](#4-github-project-完整配置方案)
5. [分支策略](#5-分支策略)
6. [验收总表](#6-验收总表)

---

## 1. 开发原则速览

| 原则 | 说明 |
|---|---|
| **结构优先** | 所有设计围绕 `Collection → Page → Node Tree → Block List` |
| **Local-first** | 本地闭环先成立，iCloud 是后续增强 |
| **简单模型** | 不过度抽象，不引入多余高阶对象 |
| **单一主路径** | 主路径流畅优先于功能覆盖广度 |
| **iPhone 先行** | 所有核心逻辑先在 iPhone 完成 |
| **晚接入同步** | 本地模型与编辑器稳定后再接入 CloudKit |

---

## 2. 整体阶段划分

```
阶段 0  MVP 范围冻结 & 定义锁定
阶段 1  工程底座（SwiftData、Theme、Router）
阶段 2  Collection 模块完成
阶段 3  Page 模块完成
阶段 4  Node Editor Core（最关键阶段）
阶段 5  Node Editor UX 补齐
阶段 6  Onboarding、示例数据、设置页
阶段 7  iCloud Sync Beta
阶段 8  UI Polish、QA、封版发布
```

### Milestone 对应关系

| Milestone | 名称 | 目标 |
|---|---|---|
| M0 | Definition | 范围锁定，文档对齐 |
| M1 | Foundation | 工程底座可运行 |
| M2 | Collections | Collection 主路径成立 |
| M3 | Pages | Collection → Page 流程稳定 |
| M4 | Node Editor Core | Node 编辑核心闭环 |
| M5 | Node Editor UX | 编辑体验顺手 |
| M6 | Onboarding & Settings | 首次使用不迷失 |
| M7 | Sync Beta | iCloud 基础同步可用 |
| M8 | QA & Release | TestFlight 可用 |

---

## 3. 阶段详细计划

---

### 阶段 0：MVP 范围冻结 & 定义锁定

**目标：** 在写第一行代码之前，对齐所有人对 MVP 的理解，确定不做什么。

#### 核心交付物

- [ ] MVP 功能范围文档（明确 In-Scope / Out-of-Scope）
- [ ] 核心用户旅程文档（一张图描述主路径）
- [ ] 数据模型初稿（Collection / Page / Node 字段定义）
- [ ] 命名规范文档（类名、文件名、变量名规则）
- [ ] Issue 模板 & PR 模板
- [ ] 分支策略说明
- [ ] 低保真线框草图（Figma）：三个主界面导航结构 + Node Editor 编辑区布局 + 关键空态

> **设计原则**：MVP 阶段不做高保真 Figma 稿。SwiftUI 本身作为原型工具，边写边验证交互手感。Figma 在此阶段只用于确认信息架构和布局方向，不涉及颜色、字体、动效。

#### Out-of-Scope（MVP 不做）

以下内容明确不进入 MVP，所有 issue 一律标记 `scope/post-mvp`：

- AI 功能（摘要、语义搜索、内容建议）
- 协作与多人编辑
- 模板市场与分享
- Map View（思维导图视图）
- 图片、代码、附件等非 text 类型 Block（bullet/image/code 均为 POST）
- 复杂导出（PDF、图片思维导图）
- Web 版 / Notte Cloud
- 跨 Page Node 引用与复用
- iPad 双栏复杂布局
- macOS 多窗口策略

#### 阶段 0 GitHub Issues

```
[M0] Define MVP in-scope feature list
[M0] Define MVP out-of-scope list
[M0] Define core user journey (single diagram)
[M0] Define Collection / Page / Node / Block data model v0
[M0] Define project naming conventions (classes, files, variables)
[M0] Create GitHub issue template
[M0] Create GitHub PR template
[M0] Define branch strategy
[M0] Create GitHub Project board and configure columns
[M0] Create all labels
[M0] Create all Milestones
[M0] Create low-fidelity wireframes in Figma (3 main screens + Node Editor layout + empty states)
```

#### 验收

- 所有团队成员（或自己）对 MVP 边界认知一致
- Out-of-Scope 列表明确，任何新想法都先进 Backlog
- GitHub Project 可用
- 低保真线框草图完成：三个主界面结构清晰，Node Editor 编辑区布局方向确定

---

### 阶段 1：工程底座

**目标：** 工程可运行，数据模型可编译，主题规范确定，核心基础设施就位。

#### 开发任务细分

##### 1.1 App 入口与路由

```swift
// App 入口结构
NotteApp.swift
AppBootstrap.swift   // 初始化 DI、数据容器、日志
AppRouter.swift      // 导航状态管理，NavigationStack / NavigationSplitView
DependencyContainer.swift  // 依赖注入容器
```

- 实现 `AppBootstrap`，完成 SwiftData container 初始化
- 实现 `AppRouter`，使用 `NavigationStack` 管理根导航路径
- 实现 `DependencyContainer`，通过 Environment 注入 Repository

##### 1.2 SwiftData 数据模型

数据层分为两部分：`Domain/Entities/` 存放纯 Swift 业务实体，`Data/Models/` 存放 SwiftData `@Model` 类。

**Domain 实体（`Domain/Entities/`，无框架依赖）**

```swift
// Domain/Entities/Collection.swift
struct Collection {
    var id: UUID
    var title: String
    var iconName: String?
    var colorToken: String?
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isPinned: Bool
}

// Domain/Entities/Page.swift
struct Page {
    var id: UUID
    var collectionID: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isArchived: Bool
}

// Domain/Entities/Node.swift
struct Node {
    var id: UUID
    var pageID: UUID
    var parentNodeID: UUID?
    var title: String        // 大纲条目名，永远存在
    var depth: Int           // 同时决定缩进层级与标题渲染级别（h1-h6，depth 0-5；超过 5 维持 h6 样式）
    var sortIndex: Double
    var isCollapsed: Bool
    var createdAt: Date
    var updatedAt: Date
}

// Domain/Entities/Block.swift
struct Block {
    var id: UUID
    var nodeID: UUID
    var type: BlockType
    var content: String      // text: 正文；image: 路径；code: 代码字符串
    var sortIndex: Double
    var createdAt: Date
    var updatedAt: Date
}

// Domain/Entities/BlockType.swift（MVP 只保留 text，POST 阶段扩展）
enum BlockType: String, Codable {
    case text                // MVP
    // POST:
    // case bullet
    // case image
    // case code
    // case quote
}
```

**SwiftData 存储模型（`Data/Models/`，与 Domain 实体保持映射关系）**

```swift
// Data/Models/CollectionModel.swift
@Model class CollectionModel {
    var id: UUID
    var title: String
    var iconName: String?
    var colorToken: String?
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isPinned: Bool
}

// Data/Models/PageModel.swift
@Model class PageModel { ... }

// Data/Models/NodeModel.swift
@Model class NodeModel { ... }

// Data/Models/BlockModel.swift
@Model class BlockModel { ... }
```

- 注意：存储模型使用**扁平结构**，不做嵌套持久化
- `sortIndex` 初始值间隔 1000，插入取相邻中间值
- Repository 负责在 `@Model` 类与 Domain 实体之间做映射转换

##### 1.3 Repository 骨架

```
Domain/Protocols/
  CollectionRepositoryProtocol
  PageRepositoryProtocol
  NodeRepositoryProtocol
  BlockRepositoryProtocol

Data/Repositories/
  CollectionRepository    ← 实现 CRUD，封装 SwiftData 操作，映射 CollectionModel ↔ Collection
  PageRepository
  NodeRepository
  BlockRepository         ← Block 的增删改查，映射 BlockModel ↔ Block
```

- Repository 只做数据操作，不包含业务逻辑
- 通过 Protocol 隔离，便于测试时 Mock
- Protocol 定义在 `Domain/Protocols/`，实现在 `Data/Repositories/`

##### 1.4 主题 Token 系统

Token 文件位于 `Shared/Theme/`：

```swift
// Shared/Theme/ColorTokens.swift（支持 Light / Dark）
struct ColorTokens {
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accent = Color("Accent")
    static let separator = Color("Separator")
}

// Shared/Theme/TypographyTokens.swift
struct TypographyTokens {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title2, design: .rounded, weight: .semibold)
    static let body = Font.system(.body)
    static let caption = Font.system(.caption)
}

// Shared/Theme/SpacingTokens.swift
struct SpacingTokens {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

##### 1.5 Logger 与 Error 基础设施

文件位于 `Infrastructure/Logging/`：

```swift
// Infrastructure/Logging/AppLogger.swift（日志抽象，方便后续切换实现）
protocol AppLogger {
    func debug(_ message: String, file: String, function: String)
    func info(_ message: String, file: String, function: String)
    func error(_ message: String, error: Error?, file: String, function: String)
}

// 错误展示 Helper（统一 Alert / Toast）
struct AppErrorPresenter {
    static func present(_ error: AppError, in viewModel: ObservableObject)
}
```

##### 1.6 调试菜单

文件位于 `Infrastructure/Debug/`：

```swift
// Infrastructure/Debug/DebugMenuView.swift（仅 #if DEBUG 编译）
struct DebugMenuView: View {
    // 清空所有数据
    // 填充示例数据
    // 查看同步日志（阶段 7 后）
}
```

#### 阶段 1 GitHub Issues

```
[M1] Bootstrap Xcode project with SwiftUI app target
[M1] Setup app entry point (NotteApp.swift)
[M1] Implement AppBootstrap with SwiftData container init
[M1] Implement AppRouter with NavigationStack
[M1] Implement DependencyContainer with Environment injection
[M1] Create Collection domain entity (Domain/Entities/Collection.swift)
[M1] Create Page domain entity (Domain/Entities/Page.swift)
[M1] Create Node domain entity (Domain/Entities/Node.swift)
[M1] Create Block domain entity (Domain/Entities/Block.swift)
[M1] Define BlockType enum in Domain/Entities/BlockType.swift (text only for MVP)
[M1] Create CollectionModel SwiftData @Model (Data/Models/CollectionModel.swift)
[M1] Create PageModel SwiftData @Model (Data/Models/PageModel.swift)
[M1] Create NodeModel SwiftData @Model (Data/Models/NodeModel.swift)
[M1] Create BlockModel SwiftData @Model (Data/Models/BlockModel.swift)
[M1] Define sortIndex policy and normalization rules
[M1] Setup Data/Persistence/PersistenceController.swift
[M1] Setup Data/Persistence/MigrationPlan.swift
[M1] Create CollectionRepositoryProtocol (Domain/Protocols/)
[M1] Create PageRepositoryProtocol (Domain/Protocols/)
[M1] Create NodeRepositoryProtocol (Domain/Protocols/)
[M1] Create BlockRepositoryProtocol (Domain/Protocols/)
[M1] Implement CollectionRepository skeleton (Data/Repositories/)
[M1] Implement PageRepository skeleton (Data/Repositories/)
[M1] Implement NodeRepository skeleton (Data/Repositories/)
[M1] Implement BlockRepository skeleton (Data/Repositories/)
[M1] Setup color tokens (Asset Catalog + Shared/Theme/ColorTokens.swift)
[M1] Setup typography tokens (Shared/Theme/TypographyTokens.swift)
[M1] Setup spacing tokens (Shared/Theme/SpacingTokens.swift)
[M1] Implement AppLogger protocol and default implementation (Infrastructure/Logging/)
[M1] Implement AppErrorPresenter helper
[M1] Create DebugMenuView in Infrastructure/Debug/ (DEBUG only)
[M1] Add SwiftData container smoke test
[M1] Add repository protocol compile test
```

#### 验收

- 工程可运行，无编译错误
- SwiftData container 正常初始化（`Data/Persistence/PersistenceController`）
- 四个 Repository skeleton 可调用（Collection / Page / Node / Block）
- Theme Token 已定义（`Shared/Theme/`），调试菜单可打开（`Infrastructure/Debug/`）
- Domain 实体（`Domain/Entities/`）与 SwiftData 模型（`Data/Models/`）字段与设计文档一致（含 Block）

---

### 阶段 2：Collection 模块

**目标：** 首页完整，Collection 的增删改查、排序、固定全部成立。

#### 架构层次

```
Features/Collections/Views/CollectionListView
  └─ Features/Collections/ViewModels/CollectionListViewModel
       └─ Features/Collections/UseCases/FetchCollectionsUseCase
       └─ Features/Collections/UseCases/CreateCollectionUseCase
       └─ Features/Collections/UseCases/RenameCollectionUseCase
       └─ Features/Collections/UseCases/DeleteCollectionUseCase
       └─ Features/Collections/UseCases/PinCollectionUseCase
       └─ Features/Collections/UseCases/ReorderCollectionsUseCase
            └─ Data/Repositories/CollectionRepository
                 └─ SwiftData
```

#### 开发任务细分

##### 2.1 UseCase 实现

每个 UseCase 独立文件，输入输出明确：

```swift
// 示例
struct CreateCollectionUseCase {
    let repository: CollectionRepositoryProtocol
    
    func execute(title: String) async throws -> CollectionEntity
}

struct ReorderCollectionsUseCase {
    let repository: CollectionRepositoryProtocol
    
    // 采用 sortIndex 中间值策略，不依赖数组下标
    func execute(moving id: UUID, after targetID: UUID?) async throws
}
```

##### 2.2 ViewModel 状态设计

```swift
@MainActor
class CollectionListViewModel: ObservableObject {
    @Published var collections: [CollectionEntity] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    // 创建弹窗状态
    @Published var isShowingCreateSheet: Bool = false
    @Published var newCollectionTitle: String = ""
    
    // 重命名状态
    @Published var renamingCollectionID: UUID?
    @Published var renameTitle: String = ""
}
```

##### 2.3 UI 组件

- `CollectionListScreen`：列表主界面，支持 EditMode 拖动排序
- `CollectionCard`：卡片展示（图标、标题、Page 数量）
- `CollectionEmptyState`：空状态（引导创建第一个 Collection）
- `CollectionCreateSheet`：底部弹窗，输入标题
- `CollectionRenameSheet`：重命名弹窗
- `CollectionDeleteDialog`：删除确认 Alert
- `CollectionContextMenu`：长按菜单（重命名、固定、删除）
- `CollectionPinnedIndicator`：固定标记

##### 2.4 排序实现要点

```swift
// sortIndex 插入策略
func insertSortIndex(between lower: Double?, and upper: Double?) -> Double {
    switch (lower, upper) {
    case (nil, nil):     return 1000.0
    case (nil, let u?):  return u / 2.0
    case (let l?, nil):  return l + 1000.0
    case (let l?, let u?): return (l + u) / 2.0
    }
}

// 定期 normalize（避免精度耗尽）
// 在后台队列中执行，间隔约 1000
func normalizeSortIndexes(_ entities: [CollectionEntity]) async throws
```

#### 阶段 2 GitHub Issues

```
[M2] Implement FetchCollectionsUseCase
[M2] Implement CreateCollectionUseCase
[M2] Implement RenameCollectionUseCase
[M2] Implement DeleteCollectionUseCase
[M2] Implement PinCollectionUseCase
[M2] Implement ReorderCollectionsUseCase with sortIndex strategy
[M2] Implement sortIndex normalization helper
[M2] Create CollectionListViewModel with full state management
[M2] Build CollectionListScreen (main list + EditMode)
[M2] Build CollectionCard component
[M2] Build CollectionEmptyState component
[M2] Build CollectionCreateSheet
[M2] Build CollectionRenameSheet
[M2] Build CollectionDeleteDialog
[M2] Build CollectionContextMenu
[M2] Build CollectionPinnedIndicator
[M2] Add collection loading state handling
[M2] Add collection error state handling
[M2] Wire navigation: CollectionListScreen → Page module (stub)
[M2] Add CollectionRepository full implementation
[M2] Add CollectionRepository unit tests
[M2] Add CreateCollectionUseCase unit tests
[M2] Add RenameCollectionUseCase unit tests
[M2] Add DeleteCollectionUseCase unit tests
[M2] Add ReorderCollectionsUseCase unit tests
[M2] Add CollectionListViewModel unit tests
[M2] Add CollectionListScreen UI flow tests
```

#### 验收

- 首页显示 Collection 列表
- 增删改查、固定、排序全部成立
- 排序结果重启后保留
- 空状态清晰，引导创建
- Collection 数量超过 10 条时无卡顿

---

### 阶段 3：Page 模块

**目标：** 进入 Collection 后，Page 层完整可用，Collection → Page 导航稳定。

#### 架构层次

```
Features/Pages/Views/PageListView
  └─ Features/Pages/ViewModels/PageListViewModel
       └─ Features/Pages/UseCases/FetchPagesByCollectionUseCase
       └─ Features/Pages/UseCases/CreatePageUseCase
       └─ Features/Pages/UseCases/RenamePageUseCase
       └─ Features/Pages/UseCases/DeletePageUseCase
       └─ Features/Pages/UseCases/DuplicatePageUseCase
       └─ Features/Pages/UseCases/ReorderPagesUseCase
            └─ Data/Repositories/PageRepository
                 └─ SwiftData
```

#### 开发任务细分

##### 3.1 UseCase 实现

```swift
struct FetchPagesByCollectionUseCase {
    func execute(collectionID: UUID) async throws -> [PageEntity]
}

struct DuplicatePageUseCase {
    // 复制 Page 元数据，同时深拷贝所有 Node（含 sortIndex 和 depth）及其 Block
    func execute(pageID: UUID) async throws -> PageEntity
}

struct DeletePageUseCase {
    // 删除 Page 同时删除其下所有 Node（事务保障）
    func execute(pageID: UUID) async throws
}
```

##### 3.2 ViewModel 状态设计

```swift
@MainActor
class PageListViewModel: ObservableObject {
    let collectionID: UUID
    
    @Published var pages: [PageEntity] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    @Published var isShowingCreateSheet: Bool = false
    @Published var newPageTitle: String = ""
    
    @Published var renamingPageID: UUID?
    @Published var renameTitle: String = ""
}
```

##### 3.3 UI 组件

- `PageListScreen`：列表主界面，支持拖动排序
- `PageRow`：行展示（标题、创建时间）
- `PageEmptyState`：空状态
- `PageCreateSheet`：创建弹窗
- `PageRenameSheet`：重命名弹窗
- `PageDeleteDialog`：删除确认
- `PageContextMenu`：长按菜单（重命名、复制、删除）

##### 3.4 删除策略

```swift
// PageRepository 中使用事务删除
func deletePage(id: UUID, context: ModelContext) throws {
    // 1. 先获取所有关联 Node id
    let nodes = try fetchNodes(pageID: id, context: context)
    // 2. 删除所有 Node 的关联 Block
    for node in nodes {
        let blocks = try fetchBlocks(nodeID: node.id, context: context)
        blocks.forEach { context.delete($0) }
    }
    // 3. 删除所有 Node
    nodes.forEach { context.delete($0) }
    // 4. 再删除 Page
    let page = try fetchPage(id: id, context: context)
    context.delete(page)
    // 3. 统一 save
    try context.save()
}
```

#### 阶段 3 GitHub Issues

```
[M3] Implement FetchPagesByCollectionUseCase
[M3] Implement CreatePageUseCase
[M3] Implement RenamePageUseCase
[M3] Implement DeletePageUseCase with cascade node deletion
[M3] Implement DuplicatePageUseCase with deep node copy
[M3] Implement ReorderPagesUseCase
[M3] Create PageListViewModel with full state management
[M3] Build PageListScreen (list + EditMode drag sort)
[M3] Build PageRow component
[M3] Build PageEmptyState component
[M3] Build PageCreateSheet
[M3] Build PageRenameSheet
[M3] Build PageDeleteDialog
[M3] Build PageContextMenu
[M3] Wire navigation: PageListScreen → NodeEditor (stub)
[M3] Implement PageRepository full implementation
[M3] Add PageRepository unit tests
[M3] Add DeletePageUseCase cascade deletion test
[M3] Add DuplicatePageUseCase deep copy test
[M3] Add ReorderPagesUseCase unit tests
[M3] Add PageListViewModel unit tests
[M3] Add PageListScreen UI flow tests
[M3] Add Collection → Page navigation integration test
```

#### 验收

- 从 Collection 正常进入 Page 列表
- Page 增删改查、复制、排序全部成立
- 删除 Page 时关联 Node 同步清理
- 大量 Page 时无卡顿
- 返回 Collection 后状态正确

---

### 阶段 4：Node Editor Core

**目标：** Node 编辑器核心闭环。这是 MVP 最关键阶段，必须保证结构正确、数据不丢。

#### 架构层次

```
Features/NodeEditor/Views/PageEditorView
  └─ Features/NodeEditor/ViewModels/PageEditorViewModel
       └─ Features/NodeEditor/Engine/NodeEditorEngine
            ├─ Features/NodeEditor/Services/NodeMutationService      ← Node 结构写操作
            ├─ Features/NodeEditor/Services/NodeQueryService         ← 所有读 / 树构建
            ├─ Features/NodeEditor/Services/BlockEditingService      ← Block 内容读写
            └─ Features/NodeEditor/Services/NodePersistenceCoordinator  ← 持久化协调
                 ├─ Data/Repositories/NodeRepository
                 ├─ Data/Repositories/BlockRepository
                 └─ SwiftData
```

命令定义位于 `Features/NodeEditor/Commands/NodeCommand.swift`。

#### 开发任务细分

##### 4.1 运行时模型（与持久化模型分离）

```swift
// 编辑器内部使用，不直接持久化
struct EditorNode: Identifiable {
    let id: UUID
    var parentID: UUID?
    var depth: Int
    var title: String            // 大纲条目名
    var isCollapsed: Bool
    var isVisible: Bool          // 由折叠状态计算得出
    var children: [EditorNode]   // 运行时树结构
    var blocks: [EditorBlock]    // 该节点下的内容块，按 sortIndex 排列
}

struct EditorBlock: Identifiable {
    let id: UUID
    var type: BlockType
    var content: String
}
```

**关键原则：** 存储模型是扁平的（`NodeEntity`），运行时模型是树形的（`EditorNode`）。两者之间的转换由 `NodeEditorEngine` 负责。

##### 4.2 命令模型

所有编辑操作统一入口，便于测试和后续快捷键绑定：

```swift
// Node 结构命令
enum NodeCommand {
    case insertAfter(nodeID: UUID)
    case insertChild(nodeID: UUID)
    case delete(nodeID: UUID)
    case moveUp(nodeID: UUID)
    case moveDown(nodeID: UUID)
    case indent(nodeID: UUID)
    case outdent(nodeID: UUID)
    case toggleCollapse(nodeID: UUID)
    case updateTitle(nodeID: UUID, title: String)
}

// Block 内容命令
enum BlockCommand {
    case addBlock(nodeID: UUID, type: BlockType)
    case deleteBlock(blockID: UUID)
    case updateContent(blockID: UUID, content: String)
    case reorderBlock(blockID: UUID, newSortIndex: Double)
}

// 统一调度入口
class NodeEditorEngine {
    func dispatch(_ command: NodeCommand) async throws
    func dispatch(_ command: BlockCommand) async throws
}
```

##### 4.3 NodeQueryService

```swift
class NodeQueryService {
    // 从扁平 NodeEntity 数组构建树
    func buildTree(from entities: [NodeEntity]) -> [EditorNode]
    
    // 计算可见节点（考虑折叠状态）
    func visibleNodes(from tree: [EditorNode]) -> [EditorNode]
    
    // 查找前一个同级节点
    func previousSibling(of nodeID: UUID, in tree: [EditorNode]) -> EditorNode?
    
    // 查找父节点
    func parent(of nodeID: UUID, in tree: [EditorNode]) -> EditorNode?
    
    // 查找所有子孙节点（用于级联删除和折叠）
    func descendants(of nodeID: UUID, in tree: [EditorNode]) -> [EditorNode]
}
```

##### 4.4 NodeMutationService 核心操作

```swift
// indent 操作逻辑
func indent(nodeID: UUID) async throws {
    // 1. 找到前一个同级节点（必须存在才能缩进）
    // 2. 将当前节点的 parentNodeID 改为前一个同级节点的 id
    // 3. depth + 1
    // 4. sortIndex 设为前一个同级节点的子节点末尾
    // 5. 批量更新当前节点的所有子孙 depth + 1
}

// outdent 操作逻辑
func outdent(nodeID: UUID) async throws {
    // 1. 找到当前父节点（必须存在才能反缩进）
    // 2. 将当前节点的 parentNodeID 改为祖父节点 id
    // 3. depth - 1
    // 4. sortIndex 设为原父节点的下一位
    // 5. 批量更新当前节点的所有子孙 depth - 1
}

// delete 操作逻辑
func delete(nodeID: UUID) async throws {
    // MVP 策略：级联删除所有子孙节点及其 Block
    // 1. 获取所有子孙节点 id（含自身）
    // 2. 删除每个节点的所有关联 Block
    // 3. 删除所有节点
    // 4. 单次事务提交
}
```

##### 4.5 PageEditorViewModel

```swift
@MainActor
class PageEditorViewModel: ObservableObject {
    let pageID: UUID
    
    @Published var visibleNodes: [EditorNode] = []
    @Published var focusedNodeID: UUID?
    @Published var saveState: SaveState = .saved   // .saved / .saving / .unsaved
    @Published var error: AppError?
    
    // 分发命令到 Engine
    func send(_ command: NodeCommand)
    
    // 加载页面数据
    func loadPage() async
}
```

##### 4.6 UI 组件

- `PageEditorView`：整体容器，持有 ScrollView + LazyVStack
- `NodeRowView`：单行渲染（类型指示器 + 缩进线 + 折叠控件 + 内容编辑器）
- `NodeContentEditor`：内容输入区（UIViewRepresentable 包装 UITextView）
- `NodeIndentationGuide`：左侧层级线
- `NodeCollapseControl`：折叠/展开箭头
- `NodeTitleEditor`：标题输入区（UIViewRepresentable 包装 UITextField 或 UITextView）
- `BlockListView`：Node 内容区，顺序渲染该 Node 的所有 Block（MVP 只有 text）
- `AddNodeButton`：行末加号（插入下一节点）

##### 4.7 键盘行为

| 操作 | 行为 |
|---|---|
| Return | `insertAfter(currentNode)`，新节点继承当前 depth，自动创建一个空 text Block |
| Backspace（title 为空且无 Block 内容） | 若有父节点：执行 `outdent`；若已在根层：执行 `delete` |
| Tab | `indent(currentNode)` |
| Shift+Tab | `outdent(currentNode)` |

#### 阶段 4 GitHub Issues

```
[M4] Define EditorNode runtime model struct
[M4] Implement NodeEditorEngine with dispatch method
[M4] Define NodeCommand enum (8 Node structure commands)
[M4] Implement NodeQueryService.buildTree (flat → tree)
[M4] Implement NodeQueryService.visibleNodes (collapse-aware)
[M4] Implement NodeQueryService.previousSibling
[M4] Implement NodeQueryService.parent
[M4] Implement NodeQueryService.descendants
[M4] Implement NodeMutationService.insertAfter
[M4] Implement NodeMutationService.insertChild
[M4] Implement NodeMutationService.delete (cascade)
[M4] Implement NodeMutationService.moveUp
[M4] Implement NodeMutationService.moveDown
[M4] Implement NodeMutationService.indent (with children depth update)
[M4] Implement NodeMutationService.outdent (with children depth update)
[M4] Implement NodeMutationService.toggleCollapse
[M4] Implement NodeMutationService.updateTitle
[M4] Define BlockCommand enum (4 Block content commands)
[M4] Implement BlockEditingService.addBlock
[M4] Implement BlockEditingService.deleteBlock
[M4] Implement BlockEditingService.updateContent
[M4] Implement BlockEditingService.reorderBlock
[M4] Implement BlockRepository full CRUD
[M4] Implement NodePersistenceCoordinator (debounce + flush)
[M4] Implement NodeRepository full CRUD
[M4] Create PageEditorViewModel with load + command dispatch
[M4] Build PageEditorView (ScrollView + LazyVStack)
[M4] Build NodeRowView (row layout + all sub-components)
[M4] Build NodeContentEditor (UITextView wrapper)
[M4] Build NodeIndentationGuide visual
[M4] Build NodeCollapseControl button
[M4] Build NodeTypeIndicator icon
[M4] Build AddNodeButton interaction
[M4] Implement keyboard Return → insertAfter behavior
[M4] Implement keyboard Backspace empty node behavior
[M4] Implement Tab → indent behavior
[M4] Implement Shift+Tab → outdent behavior
[M4] Add NodeQueryService.buildTree unit tests
[M4] Add NodeQueryService.visibleNodes unit tests
[M4] Add NodeMutationService.insertAfter unit tests
[M4] Add NodeMutationService.indent unit tests
[M4] Add NodeMutationService.outdent unit tests
[M4] Add NodeMutationService.delete cascade unit tests
[M4] Add NodeMutationService.moveUp/moveDown unit tests
[M4] Add NodeMutationService.toggleCollapse unit tests
[M4] Add BlockEditingService.addBlock unit tests
[M4] Add BlockEditingService.deleteBlock unit tests
[M4] Add BlockEditingService.updateContent unit tests
[M4] Add PageEditorViewModel load test
[M4] Add end-to-end: create node → persist → relaunch → verify
```

#### 验收

- 可输入 Node 标题并编辑 Block 内容
- 新增、删除、缩进、反缩进、上下移动正常
- 折叠 / 展开后可见性计算正确
- 重启后数据保留，结构不乱
- 多层级嵌套（≥5 层）不出现视觉或数据错误

---

### 阶段 5：Node Editor UX 补齐

**目标：** 从"能用"升级为"顺手"，确保自动保存可靠、体验流畅。

#### 开发任务细分

##### 5.1 自动保存策略

```swift
class NodePersistenceCoordinator {
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 0.8  // 800ms
    
    // 触发 debounce 保存
    func scheduleAutosave(for pageID: UUID) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await flush(pageID: pageID)
        }
    }
    
    // 强制立即保存（退出页面、进入后台时调用）
    func flush(pageID: UUID) async
}

// 监听 App 生命周期，强制 flush
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
    viewModel.forceFlush()
}
```

##### 5.2 焦点状态管理

```swift
// 焦点转移逻辑
enum FocusTarget: Hashable {
    case node(UUID)
}

// 规则
// - insertAfter 后，焦点自动转移到新节点
// - delete 后，焦点转移到前一个可见节点
// - indent / outdent 后，焦点保持在当前节点
// - moveUp / moveDown 后，焦点跟随节点
```

##### 5.3 长列表性能优化

```swift
// 使用 LazyVStack，避免全量渲染
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(viewModel.visibleNodes) { node in
            NodeRowView(node: node)
                .id(node.id)  // 确保焦点滚动定位正确
        }
    }
}
// 滚动定位到聚焦节点
.onChange(of: viewModel.focusedNodeID) { id in
    if let id { proxy.scrollTo(id, anchor: .center) }
}
```

##### 5.4 工具条（Toolbar）

MVP 工具条只做最小集：

```
[ 缩进 ] [ 反缩进 ] [ 完成（收键盘） ]
```

- 键盘弹起时工具条自动显示在键盘上方
- Block 类型切换（text 之外的类型）属于 POST 阶段功能，MVP 不做

#### 阶段 5 GitHub Issues

```
[M5] Implement debounce autosave (800ms interval)
[M5] Implement force flush on page exit
[M5] Implement force flush on app background
[M5] Implement focus auto-transfer after insertAfter
[M5] Implement focus auto-transfer after delete
[M5] Implement focus preservation after indent/outdent
[M5] Implement focus tracking after moveUp/moveDown
[M5] Optimize NodeRowView with LazyVStack
[M5] Implement scroll-to-focused-node behavior
[M5] Build editor keyboard toolbar (indent/outdent/type/done)
[M5] Implement node type switcher in toolbar
[M5] Improve NodeRow visual spacing and padding
[M5] Improve indentation hierarchy visual (depth guides)
[M5] Improve collapse animation (withAnimation)
[M5] Improve selected row highlight color
[M5] Add editor empty page state (first node prompt)
[M5] Add autosave unit tests
[M5] Add focus transition unit tests
[M5] Add long page (100+ nodes) performance test
[M5] Add page exit save reliability test
[M5] Add app background save reliability test
```

#### 验收

- 长页面（100+ Node）滚动流畅，无明显卡顿
- 自动保存可靠：强制退出后重进数据不丢
- 回车和退格行为符合直觉
- 工具条在键盘弹起时正确显示
- 编辑器层级感清晰，折叠动画自然

---

### 阶段 6：Onboarding、示例数据、设置页

**目标：** 新用户首次打开不迷失，3 分钟内理解核心模型。

#### 开发任务细分

##### 6.1 Onboarding 3 屏结构

```
屏 1 - 产品理念
  标题：结构化地记录一切
  副标题：Notte 帮助你快速记录，自然形成结构，长期积累知识。
  图示：Collection / Page / Node 层级图（静态 SVG 或 SwiftUI 绘制）

屏 2 - 核心模型说明
  标题：三个对象，一套系统
  Collection → 专题空间
  Page → 完整页面
  Node → 内容模块（可自由移动、重组）

屏 3 - 开始使用
  [创建我的第一个 Collection]  ← 进入主页，弹出创建 sheet
  [导入示例数据]               ← 导入预置示例后进入主页
```

##### 6.2 示例数据工厂

示例数据以 JSON 文件存储于 `Resources/SampleData/`（`SwiftUILearning.json`、`ProjectPlanning.json`、`ReadingNotes.json`），由 `AppBootstrap` 在首次运行时读取并导入。

```swift
struct ExampleDataFactory {
    static func create(from jsonFile: String, in context: ModelContext) throws {
        // 读取 Resources/SampleData/<jsonFile>.json
        // 解析后创建 CollectionModel → PageModel → NodeModel 树
    }
}

// SwiftUI 学习示例结构（SwiftUILearning.json）
// Collection: "SwiftUI 学习"
//   Page: "SwiftUI 基础"
//     Node: "什么是 SwiftUI" (heading)
//     Node: "声明式语法" (bullet)
//     Node: "View 协议" (bullet)
//   Page: "布局系统"
//     Node: "HStack / VStack / ZStack" (heading)
//     ...
```

##### 6.3 首次运行检测

```swift
// AppStorage 存储首次运行标记
@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

// 在 AppBootstrap 中判断是否展示 Onboarding
if !hasCompletedOnboarding {
    router.presentOnboarding()
}
```

##### 6.4 设置页结构

```
设置
  ├ iCloud 同步
  │   ├ 同步状态（已开启 / 未开启 / 同步中 / 上次同步时间）
  │   └ 开关（阶段 7 后生效）
  ├ 外观
  │   └ 跟随系统（说明文本，暂不提供手动切换）
  ├ 关于 Notte
  │   ├ 版本号
  │   ├ 反馈入口（打开邮件 / 表单链接）
  │   └ 隐私政策链接
  └ 调试（仅 DEBUG）
      ├ 填充示例数据
      ├ 清空所有数据
      └ 查看日志
```

#### 阶段 6 GitHub Issues

```
[M6] Build OnboardingView screen 1 (concept + hierarchy illustration)
[M6] Build OnboardingView screen 2 (Collection/Page/Node explanation)
[M6] Build OnboardingView screen 3 (CTA: create or import)
[M6] Implement skip onboarding action
[M6] Implement "create first collection" CTA from onboarding
[M6] Implement "import example data" CTA from onboarding
[M6] Implement first-run detection with AppStorage flag
[M6] Create ExampleDataFactory protocol and structure
[M6] Create SwiftUI learning JSON sample data (Resources/SampleData/SwiftUILearning.json, 3 pages, 12+ nodes)
[M6] Create project planning JSON sample data (Resources/SampleData/ProjectPlanning.json, 3 pages, 10+ nodes)
[M6] Create reading notes JSON sample data (Resources/SampleData/ReadingNotes.json, 2 pages, 8+ nodes)
[M6] Build SettingsView main screen
[M6] Build iCloud sync status section (placeholder for M7)
[M6] Build appearance section (system follows explanation)
[M6] Build about section (version + feedback + privacy)
[M6] Build debug section (fill/clear data, view logs)
[M6] Add onboarding completion persistence test
[M6] Add example data import integrity test (node count, depth)
[M6] Add onboarding screen navigation UI test
[M6] Add settings screen render test
```

#### 验收

- 新用户首次打开看到 Onboarding，3 屏引导清晰
- 导入示例数据后首页有内容，可直接浏览
- 设置页完整，各入口可点击
- Onboarding 完成标记持久化，重启后不再展示
- 示例数据结构正确，Node 层级无误

---

### 阶段 7：iCloud Sync Beta

**目标：** 最小可用同步，不破坏本地闭环。

**前置条件：** 阶段 4 数据模型字段已稳定，至少两周内无 breaking change。

#### 开发任务细分

##### 7.1 CloudKit 配置

```
1. Xcode > Signing & Capabilities > + iCloud
2. 勾选 CloudKit，选择 container（如 iCloud.com.yourname.notte）
3. 在 SwiftData container 初始化时传入 CloudKit container identifier

let schema = Schema([CollectionEntity.self, PageEntity.self, NodeEntity.self])
let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
let container = try ModelContainer(for: schema, configurations: [config])
```

##### 7.2 同步阶段策略

**阶段 A（本阶段不做）：** 纯本地，不接 CloudKit。

**阶段 B（本阶段）：** 接入 CloudKit 容器，只做基础推拉。不做冲突可视化，不做复杂合并。

**阶段 C（Post-MVP）：** 加入同步状态展示和更精细的冲突策略。

##### 7.3 冲突策略

```swift
// MVP 采用 Last Write Wins
// SwiftData + CloudKit 默认行为即 LWW，无需额外实现
// 确保所有 Entity 都有 updatedAt 字段，CloudKit 用它决定最新版本
```

##### 7.4 同步状态展示

```swift
// 设置页中展示
struct SyncStatusView: View {
    @AppStorage("lastSyncDate") var lastSyncDate: Double = 0
    
    var body: some View {
        if lastSyncDate > 0 {
            Text("上次同步：\(formattedDate)")
        } else {
            Text("尚未同步")
        }
    }
}
```

##### 7.5 同步失败处理

```swift
// 监听 CloudKit 错误通知
NotificationCenter.default.addObserver(
    forName: NSPersistentCloudKitContainer.eventChangedNotification,
    object: nil,
    queue: .main
) { notification in
    if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
        as? NSPersistentCloudKitContainer.Event,
       event.error != nil {
        // 记录错误日志，展示简短提示 Toast
    }
}
```

#### 阶段 7 GitHub Issues

```
[M7] Configure CloudKit container in Xcode capabilities
[M7] Enable SwiftData CloudKit sync in ModelContainer init
[M7] Add sync environment config (debug vs production container)
[M7] Add CloudKit sync logger
[M7] Add CloudKit error notification observer
[M7] Map CloudKit error types to AppError
[M7] Update SettingsView iCloud section with real sync status
[M7] Implement lastSyncDate AppStorage tracking
[M7] Add sync failure toast notification
[M7] Add debug: manual CloudKit push/pull trigger
[M7] Add debug: view CloudKit sync log
[M7] Test: Device A creates Collection, Device B receives
[M7] Test: Device A renames Page, Device B receives rename
[M7] Test: Device A deletes Node, Device B node disappears
[M7] Test: offline edit on Device A, reconnect, Device B syncs
[M7] Test: local data remains intact when sync fails
[M7] Test: no editor regression after CloudKit integration
[M7] Verify: Collection list screen with sync enabled
[M7] Verify: Node editor with sync enabled (no crashes)
```

#### 验收

- 两设备间基础 CRUD 同步可用
- 同步失败不破坏本地数据
- 本地主路径（无 iCloud）仍完整成立
- 编辑器无因同步引入的崩溃或数据错误
- 设置页同步状态有基础可见性

---

### 阶段 8：UI Polish、QA、封版发布

**目标：** 视觉统一、主路径无阻塞 Bug、TestFlight 可分发。

#### 开发任务细分

##### 8.1 UI Polish 清单

- Collection Card：阴影、圆角、图标颜色一致性
- Page Row：间距、字重、辅助信息（时间）视觉层次
- Node Row：深度线颜色、类型图标大小、选中态背景
- 深色模式：逐屏检查 Color Token 适配
- 间距统一：全局检查是否使用 Token（不出现魔法数字）
- 字体统一：全局检查是否使用 Token
- 空状态视觉：Collection / Page / Node 三处空状态插图或图标
- 删除确认：文案清晰（"删除后不可恢复" / "包含 X 个 Page"）
- Loading 态：首次加载骨架屏或 ProgressView
- **Figma 精稿**：对照实现完成后，在 Figma 中补全高保真视觉稿（颜色、字体、图标、间距），作为 App Store 截图和后续迭代的设计基准

##### 8.2 回归测试清单

```
主路径回归
  □ 创建 Collection → 创建 Page → 创建 Node → 退出重进 → 数据保留
  □ 缩进 3 层 → 退出 → 重进 → 层级正确
  □ 删除有子节点的 Node → 子节点一并消失
  □ 删除 Page → Page 下所有 Node 清理
  □ 删除 Collection → Collection 下所有 Page/Node 清理
  □ 导入示例数据 → 内容正确
  □ 重命名 → 刷新后标题正确

编辑器回归
  □ 100 个 Node 的页面滚动流畅
  □ 5 层嵌套 → 折叠 → 展开 → 结构正确
  □ Node 标题编辑 → Block 内容编辑 → 重启数据不丢
  □ 回车插入 → 焦点跳转 → 继续输入
  □ 退格删除空 Node → 焦点转移正确
  □ App 进后台 → 前台 → 数据不丢

同步回归（若已接入）
  □ 两设备基础同步
  □ 离线编辑 → 上线同步

小屏适配（iPhone SE）
  □ Collection 列表无截断
  □ Node Editor 可正常编辑
  □ 工具条不遮挡内容

Dynamic Type
  □ 最大字号下布局不破
```

##### 8.3 TestFlight 发布准备

```
□ App Icon 所有尺寸提供
□ Launch Screen 正确
□ Bundle ID / Version / Build 正确
□ 隐私权限说明（iCloud 使用说明）
□ TestFlight What to Test 说明文档
□ TestFlight 反馈表单链接就位
□ App Store 截图脚本（至少 3 张主路径截图）
```

#### 阶段 8 GitHub Issues

```
[M8] Polish CollectionCard visual (shadow, corner, icon color)
[M8] Polish PageRow visual (spacing, weight, date info)
[M8] Polish NodeRow visual (depth guides, h1-h6 title rendering, selection bg)
[M8] Audit and fix dark mode for CollectionListScreen
[M8] Audit and fix dark mode for PageListScreen
[M8] Audit and fix dark mode for PageEditorView
[M8] Audit and fix dark mode for SettingsView
[M8] Audit global spacing for magic numbers, replace with tokens
[M8] Audit global typography for magic values, replace with tokens
[M8] Improve CollectionList empty state illustration
[M8] Improve PageList empty state illustration
[M8] Improve NodeEditor empty state prompt
[M8] Improve delete confirmation copy (warn cascade effects)
[M8] Add loading skeleton or ProgressView for initial load
[M8] Create Figma hi-fi design reference (colors, typography, icons, spacing)
[M8] Run and fix main path regression checklist
[M8] Run and fix editor regression checklist
[M8] Run sync regression checklist
[M8] Run iPhone SE small screen layout checks
[M8] Run Dynamic Type max size layout checks
[M8] Run crash path checks (force quit during edit, etc.)
[M8] Prepare App Icon all sizes
[M8] Verify Launch Screen renders correctly
[M8] Set correct Bundle ID / Version / Build number
[M8] Write Privacy permission descriptions (iCloud)
[M8] Write TestFlight What to Test document
[M8] Add feedback form URL to Settings
[M8] Create App Store screenshot script (3+ key screens)
[M8] Create MVP regression checklist document
[M8] Tag and archive MVP release commit
[M8] Prepare post-MVP backlog (first 10 issues for next cycle)
```

#### 验收

- 主路径无阻塞 Bug
- 深浅色模式全部页面可用
- iPhone SE 不出现布局破损
- Dynamic Type 最大字号下基本可用
- TestFlight Build 可安装、可演示
- 有明确的下一阶段 Backlog

---

## 4. GitHub Project 完整配置方案

### 4.1 看板列

```
Backlog          ← 未排入计划，待评估
Planned          ← 已确认进入当前 Milestone
Ready            ← 可以立刻开始（依赖已解决）
In Progress      ← 正在开发
Blocked          ← 有阻塞（标注阻塞原因）
In Review        ← PR 已提交，等待 Review
QA               ← 功能完成，等待验收测试
Done             ← 已完成并关闭
```

### 4.2 Milestone 完整列表

| ID | 名称 | 描述 |
|---|---|---|
| M0 | Definition | MVP 范围冻结，文档对齐 |
| M1 | Foundation | 工程底座可运行 |
| M2 | Collections | Collection 主路径 |
| M3 | Pages | Page 主路径 |
| M4 | Node Editor Core | Node 编辑核心闭环 |
| M5 | Node Editor UX | 编辑体验顺手 |
| M6 | Onboarding & Settings | 首次使用不迷失 |
| M7 | Sync Beta | iCloud 基础同步 |
| M8 | QA & Release | TestFlight 可用 |

### 4.3 Labels 完整列表

#### 模块（area）

```
area/app           ← App 入口、路由、启动
area/collection    ← Collection 模块
area/page          ← Page 模块
area/node-editor   ← Node 编辑器
area/persistence   ← 持久化
area/sync          ← iCloud 同步
area/ui            ← 通用 UI 组件、Theme
area/onboarding    ← 引导流程
area/settings      ← 设置页
area/release       ← 发布相关
area/testing       ← 测试
area/docs          ← 文档
```

#### 类型（type）

```
type/feature       ← 新功能
type/bug           ← Bug 修复
type/refactor      ← 重构
type/test          ← 新增或修改测试
type/docs          ← 文档
type/chore         ← 构建、配置、依赖
type/perf          ← 性能优化
```

#### 优先级（priority）

```
priority/p0        ← 阻塞主路径，必须立即修复
priority/p1        ← 当前 Milestone 必须完成
priority/p2        ← 当前 Milestone 尽量完成
priority/p3        ← 可延后到下个 Milestone
```

#### 范围（scope）

```
scope/mvp          ← MVP 范围内
scope/post-mvp     ← MVP 之后再做
```

#### 平台（platform）

```
platform/shared    ← 跨平台共用逻辑
platform/ios       ← iPhone 专属
platform/ipad      ← iPad 专属
platform/macos     ← macOS 专属
```

#### 状态（status）

```
status/needs-design    ← 需要先确定设计方案
status/needs-decision  ← 需要决策后才能开始
status/blocked         ← 依赖其他 issue 未完成
status/wontfix         ← 确认不修复
```

### 4.4 Issue 模板

#### Feature Issue 模板

```markdown
## 功能描述
<!-- 这个 issue 要实现什么 -->

## 验收标准
<!-- 怎样算完成，尽量可测试 -->
- [ ] 
- [ ] 
- [ ] 

## 技术说明
<!-- 实现要点、注意事项、相关类/文件 -->

## 相关 Issue
<!-- 依赖或关联的 issue -->
Depends on: #
Related: #

## Milestone
<!-- M0 ~ M8 -->
```

#### Bug Issue 模板

```markdown
## 问题描述
<!-- 发生了什么 -->

## 复现步骤
1. 
2. 
3. 

## 预期行为
<!-- 应该发生什么 -->

## 实际行为
<!-- 实际发生什么 -->

## 环境
- 设备：
- iOS 版本：
- App 版本 / Build：

## 截图 / 日志
<!-- 如有 -->
```

### 4.5 PR 模板

```markdown
## 改动描述
<!-- 这个 PR 做了什么 -->

## 关联 Issue
Closes #
Related: #

## 改动类型
- [ ] 新功能 (type/feature)
- [ ] Bug 修复 (type/bug)
- [ ] 重构 (type/refactor)
- [ ] 测试 (type/test)
- [ ] 文档 (type/docs)
- [ ] 构建/配置 (type/chore)

## 测试情况
- [ ] 新增了单元测试
- [ ] 已在真机上验证
- [ ] 已验证深色模式
- [ ] 已验证 iPhone SE 布局

## 截图（UI 改动时必填）
| Before | After |
|--------|-------|
|        |       |

## 注意事项
<!-- Review 时需要关注的点 -->
```

### 4.6 Project Views 推荐

除默认 Board 视图外，建议创建：

| View 名称 | 类型 | 用途 |
|---|---|---|
| Board | Board | 日常看任务状态 |
| By Milestone | Board grouped by Milestone | 看各阶段进度 |
| By Priority | Board grouped by Priority | 排优先级 |
| Roadmap | Roadmap | 看整体时间线 |
| All Issues | Table | 批量管理 / 搜索 |

### 4.7 自动化规则（GitHub Actions）

```yaml
# 当 PR 合并到 main 时，自动把关联 Issue 移到 Done
# 在 GitHub Project Settings > Workflows 中开启：
# "Auto-archive items" + "Auto-close issue on PR merge"

# 可选：当 Issue 被 assign 时，自动移到 In Progress
# 当 PR 提交时，自动移到 In Review
```

---

## 5. 分支策略

### 分支命名规范

```
main              ← 稳定可运行，只通过 PR 合并
develop           ← 开发集成分支（可选，小团队可省略）

feature/m2-collection-list-screen
feature/m4-node-editor-engine
feature/m4-node-mutation-service
bugfix/m4-indent-depth-calculation
refactor/m3-page-repository-protocol
chore/m1-setup-swiftdata-container
docs/m0-mvp-scope-definition
```

### 分支规则

- `main` 开启 Branch Protection：至少 1 次 Review，CI 通过后才可合并
- 功能分支命名格式：`type/milestone-brief-description`
- 每个 Milestone 结束时，在 `main` 上打 Tag：`v0.1.0-m2`、`v0.1.0-m4` 等

### Commit Message 规范

```
feat(collection): add reorder use case with sortIndex strategy
fix(node-editor): correct indent depth calculation for nested nodes  
refactor(persistence): extract NodeRepository from PageRepository
test(collection): add reorder use case unit tests
chore(project): setup SwiftData container and schema
docs(mvp): update node mutation service spec
```

格式：`type(area): description`

---

## 6. 验收总表

| 阶段 | 核心验收条件 |
|---|---|
| **M0** | MVP 边界对齐，GitHub Project 配置完毕 |
| **M1** | 工程可运行，SwiftData 初始化，Token 已定义 |
| **M2** | Collection 增删改查、固定、排序全部成立，空状态可用 |
| **M3** | Collection → Page 导航稳定，Page CRUD 完整，级联删除正确 |
| **M4** | Node 编辑核心闭环：增删缩进移动折叠全部成立，Block 内容可编辑，重启数据不丢 |
| **M5** | 自动保存可靠，长页面流畅，键盘行为符合直觉，工具条可用 |
| **M6** | 首次使用不迷失，示例数据可导入，设置页完整 |
| **M7** | 两设备基础同步可用，本地主路径不受影响，同步失败不破坏数据 |
| **M8** | 主路径无阻塞 Bug，深浅色可用，TestFlight 可安装可演示 |

---

> **一条主线，始终不变：**
>
> ```
> Collection → Page → Node → Block
> ```
>
> 任何不在这条链路上的能力，都不进入 MVP。
