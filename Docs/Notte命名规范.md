# Notte 命名规范

> 适用阶段：MVP 全程及后续迭代  
> 适用规模：1 人主导开发，最多 2 人协作  
> 参考标准：[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)  
> 最后更新：2026-03

---

## 目录

1. [总原则](#1-总原则)
2. [文件命名](#2-文件命名)
3. [类型命名（类 / 结构体 / 枚举 / Protocol）](#3-类型命名)
4. [变量与属性命名](#4-变量与属性命名)
5. [函数与方法命名](#5-函数与方法命名)
6. [枚举 Case 命名](#6-枚举-case-命名)
7. [Protocol 命名](#7-protocol-命名)
8. [SwiftUI 视图命名](#8-swiftui-视图命名)
9. [SwiftData 模型命名](#9-swiftdata-模型命名)
10. [ViewModel 命名](#10-viewmodel-命名)
11. [UseCase / Service 命名](#11-usecase--service-命名)
12. [常量与静态值命名](#12-常量与静态值命名)
13. [测试命名](#13-测试命名)
14. [常见反例](#14-常见反例)

---

## 1. 总原则

遵循 Swift 官方 API Design Guidelines 的三条核心原则：

### 1.1 清晰优先于简洁

> "Clarity at the point of use is your most important goal."

代码被阅读的次数远多于被写的次数，优先让调用处清晰易读，而非减少输入字符。

```swift
// ✅ 清晰
collections.remove(at: index)

// ❌ 过度简化，意图不明
collections.remove(index)
```

### 1.2 避免歧义，不做无意义缩写

缩写只有在整个 Swift 生态中广泛接受的情况下才可使用（如 `URL`、`ID`、`UI`、`JSON`）。  
项目自创缩写一律禁止。

```swift
// ✅
var collectionID: UUID
var pageTitle: String

// ❌ 自创缩写
var colID: UUID
var pgTtl: String
```

### 1.3 命名包含语义，不重复类型

变量名应表达"是什么"，不需要重复类型信息（匈牙利命名法风格禁止）。

```swift
// ✅
var title: String
var collections: [Collection]

// ❌ 类型信息重复
var titleString: String
var collectionsArray: [Collection]
```

---

## 2. 文件命名

| 类型 | 规则 | 示例 |
|---|---|---|
| Swift 源文件 | UpperCamelCase，与主要类型同名 | `CollectionListView.swift` |
| SwiftData 模型 | 类型名 + `Model` | `CollectionModel.swift` |
| 测试文件 | 被测类型名 + `Tests` | `CollectionRepositoryTests.swift` |
| 资源文件 | 小写，单词用连字符 `-` 分隔 | `sample-collections.json` |
| 文档文件 | 中文标题或英文标题均可，`.md` 后缀 | `命名规范.md` |

**一个文件只包含一个主要类型**（Protocol extension 可例外）。  
文件名必须与其中的主要类型名完全一致。

---

## 3. 类型命名

**规则：UpperCamelCase，名词或名词短语。**

### 3.1 领域实体（Domain Entities）

```swift
struct Collection { }
struct Page { }
struct Node { }
struct Block { }
```

### 3.2 SwiftData 模型

在领域实体名后加 `Model` 后缀，区分纯 Swift 结构体和 `@Model` 类。

```swift
@Model class CollectionModel { }
@Model class PageModel { }
@Model class NodeModel { }
@Model class BlockModel { }
```

### 3.3 视图（SwiftUI Views）

```swift
struct CollectionListView: View { }
struct PageEditorView: View { }
struct NodeRowView: View { }
```

### 3.4 ViewModel

```swift
@Observable class CollectionListViewModel { }
@Observable class PageEditorViewModel { }
```

### 3.5 UseCase

```swift
struct CreateCollectionUseCase { }
struct DeletePageUseCase { }
struct IndentNodeUseCase { }
```

### 3.6 Service

```swift
struct NodeMutationService { }
struct NodeQueryService { }
struct BlockEditingService { }
```

### 3.7 Repository

```swift
protocol CollectionRepository { }
struct SwiftDataCollectionRepository: CollectionRepository { }
```

### 3.8 Engine

```swift
class NodeEditorEngine { }
```

---

## 4. 变量与属性命名

**规则：lowerCamelCase，名词或名词短语。**

### 4.1 基本属性

```swift
var id: UUID
var title: String
var sortIndex: Double
var createdAt: Date
var updatedAt: Date
```

### 4.2 布尔属性：用 `is` / `has` / `can` / `should` 前缀

布尔属性读起来应像断言，而不是名词。

```swift
// ✅
var isPinned: Bool
var isCollapsed: Bool
var isArchived: Bool
var hasChildren: Bool
var canIndent: Bool

// ❌ 名词形式，无法断言
var pinned: Bool
var collapsed: Bool
```

### 4.3 可选值：不加 `optional` / `nullable` 后缀，直接用 `?`

```swift
// ✅
var parentNodeID: UUID?
var iconName: String?
var colorToken: String?

// ❌
var optionalParentNodeID: UUID?
```

### 4.4 集合类型：用复数名词

```swift
var collections: [Collection]
var pages: [Page]
var nodes: [Node]
var visibleNodes: [Node]
```

### 4.5 关联 ID：类型名 + `ID`（大写，非 `Id`）

Swift 官方 API（如 `ProcessInfo.processIdentifier`）与 Foundation 惯用 `ID`（全大写缩写）。

```swift
var collectionID: UUID
var pageID: UUID
var parentNodeID: UUID?
var nodeID: UUID
```

### 4.6 深度与层级

```swift
var depth: Int          // Node 深度，0 = h1，1 = h2，…
var sortIndex: Double   // 排序索引，使用 Double 支持插入不重排
```

---

## 5. 函数与方法命名

**规则：lowerCamelCase，动词或动词短语开头，参数标签让调用处读起来像自然语言。**

### 5.1 基本规则

```swift
// ✅ 调用处读起来流畅
func createCollection(title: String) throws -> Collection
func deletePage(_ page: Page) throws
func indentNode(_ node: Node) throws
func moveNode(_ node: Node, to parent: Node?, at index: Int) throws
```

### 5.2 有副作用 vs 纯函数：动词 vs 名词

| 情况 | 命名形式 | 示例 |
|---|---|---|
| 有副作用（修改状态） | 动词形式 | `sort()`, `append(_:)`, `indent(_:)` |
| 无副作用（返回新值） | 名词/形容词形式 | `sorted()`, `appending(_:)`, `indented()` |

```swift
// 修改自身（有副作用）
mutating func indent()
mutating func collapse()

// 返回新值（无副作用）
func indented() -> Node
func collapsed() -> Node
```

### 5.3 工厂方法

用 `make` 前缀（Swift 常见约定）。

```swift
static func makeEmpty() -> Node
static func makeDefault(in page: Page) -> Collection
```

### 5.4 异步方法

SwiftUI/async-await 场景，方法名本身不加 `async` 后缀，由 `async` 关键字体现。

```swift
func fetchCollections() async throws -> [Collection]
func saveNode(_ node: Node) async throws
```

### 5.5 第一个参数标签省略的场景

当方法名已包含参数语义时，第一个参数标签省略：

```swift
// ✅ 不重复
collections.append(collection)
nodes.remove(node)

// ❌ 重复
collections.append(collection: collection)
```

---

## 6. 枚举 Case 命名

**规则：lowerCamelCase（Swift 3 起的标准）。**

```swift
enum BlockType: String, Codable {
    case text
    // POST:
    // case bullet
    // case image
    // case code
    // case quote
}

enum SyncState {
    case idle
    case syncing
    case succeeded
    case failed(Error)
}

enum NodeEditorCommand {
    case insert(after: Node)
    case delete(Node)
    case indent(Node)
    case outdent(Node)
    case merge(Node, into: Node)
    case split(Node, at: Int)
}
```

---

## 7. Protocol 命名

### 7.1 描述"是什么"的 Protocol：名词，不加后缀

```swift
protocol Collection { }     // 不推荐（与标准库冲突，仅示意）
protocol Repository { }
```

### 7.2 描述"能做什么"的 Protocol：动词 + `-able` / `-ing`

```swift
protocol Sortable { }
protocol Collapsible { }
protocol Persistable { }
```

### 7.3 Repository / Service Protocol：类型名 + 职责名

Notte 项目中，Repository 和 Service 均定义 Protocol：

```swift
protocol CollectionRepository {
    func fetchAll() async throws -> [Collection]
    func save(_ collection: Collection) async throws
    func delete(_ collection: Collection) async throws
}

protocol PageRepository {
    func fetchPages(in collectionID: UUID) async throws -> [Page]
    func save(_ page: Page) async throws
    func delete(_ page: Page) async throws
}
```

---

## 8. SwiftUI 视图命名

### 8.1 View 后缀

所有 `View` 结构体必须以 `View` 结尾：

```swift
struct CollectionListView: View { }
struct CollectionCardView: View { }
struct PageEditorView: View { }
struct NodeRowView: View { }
struct EmptyStateView: View { }
struct DeleteConfirmDialog: View { }  // Dialog 也可接受
```

### 8.2 ViewModifier

以 `Modifier` 结尾：

```swift
struct DepthIndentModifier: ViewModifier { }
struct NodeHighlightModifier: ViewModifier { }
```

### 8.3 预览

```swift
#Preview {
    CollectionListView()
}
```

### 8.4 子视图拆分

内部私有子视图也遵循 `View` 后缀，用 `private` 修饰：

```swift
// 在 PageEditorView.swift 内部
private struct NodeListSection: View { }
private struct ToolbarActionsView: View { }
```

---

## 9. SwiftData 模型命名

SwiftData `@Model` 类与 Domain 实体同名加 `Model`，字段命名与 Domain 实体一致：

```swift
@Model
class CollectionModel {
    var id: UUID
    var title: String
    var iconName: String?
    var colorToken: String?
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isPinned: Bool
}

@Model
class NodeModel {
    var id: UUID
    var pageID: UUID
    var parentNodeID: UUID?
    var title: String
    var depth: Int
    var sortIndex: Double
    var isCollapsed: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

---

## 10. ViewModel 命名

### 10.1 命名规则

`[对应视图名，去掉 View 后缀]` + `ViewModel`：

```swift
@Observable class CollectionListViewModel { }
@Observable class PageEditorViewModel { }
@Observable class OnboardingViewModel { }
```

### 10.2 内部属性

Published / `@Observable` 属性遵循同样的变量命名规则：

```swift
@Observable class CollectionListViewModel {
    var collections: [Collection] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var selectedCollection: Collection? = nil
}
```

### 10.3 Action 方法

ViewModel 的交互方法用动词命名：

```swift
func loadCollections() async
func createCollection(title: String) async
func deleteCollection(_ collection: Collection) async
func togglePin(for collection: Collection) async
```

---

## 11. UseCase / Service 命名

### 11.1 UseCase：动词 + 宾语 + `UseCase`

```swift
struct CreateCollectionUseCase { }
struct RenameCollectionUseCase { }
struct DeleteCollectionUseCase { }
struct PinCollectionUseCase { }
struct FetchCollectionsUseCase { }

struct CreatePageUseCase { }
struct ArchivePageUseCase { }

struct InsertNodeUseCase { }
struct DeleteNodeUseCase { }
struct IndentNodeUseCase { }
struct OutdentNodeUseCase { }
struct MoveNodeUseCase { }
struct MergeNodeUseCase { }
struct SplitNodeUseCase { }
```

### 11.2 UseCase 执行方法：统一用 `execute`

```swift
struct CreateCollectionUseCase {
    func execute(title: String) throws -> Collection
}
```

### 11.3 Service：名词（职责域） + `Service`

```swift
struct NodeMutationService { }   // 负责 Node 结构层变更
struct NodeQueryService { }      // 负责树构建、可见性计算
struct BlockEditingService { }   // 负责 Block 内容层变更
```

---

## 12. 常量与静态值命名

### 12.1 全局常量：lowerCamelCase（Swift 不用 `k` 前缀）

```swift
// ✅ Swift 风格
let defaultSortIndex: Double = 1000.0
let maxCollectionTitleLength: Int = 100

// ❌ Objective-C 遗留风格
let kDefaultSortIndex: Double = 1000.0
```

### 12.2 设计 Token：静态属性在专属类型内

```swift
enum ColorTokens {
    static let primaryBackground = Color("PrimaryBackground")
    static let accent = Color("Accent")
    static let danger = Color("Danger")
    static let secondaryLabel = Color("SecondaryLabel")
}

enum TypographyTokens {
    static let h1: Font = .system(size: 28, weight: .bold)
    static let h2: Font = .system(size: 22, weight: .semibold)
    static let body: Font = .system(size: 16, weight: .regular)
}

enum SpacingTokens {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

### 12.3 深度相关常量

```swift
enum NodeDepth {
    static let min: Int = 0      // h1
    static let maxHeading: Int = 5  // h6
    // depth > maxHeading 时维持 h6 样式，只增加缩进
}
```

---

## 13. 测试命名

### 13.1 测试类：被测类型 + `Tests`

```swift
final class CollectionRepositoryTests: XCTestCase { }
final class NodeEditorEngineTests: XCTestCase { }
final class NodeMutationServiceTests: XCTestCase { }
```

### 13.2 测试方法：`test` + 场景描述（camelCase）

格式建议：`test_[被测方法]_[场景]_[预期结果]`（下划线分隔三段，内部用 camelCase）

```swift
func test_createCollection_withValidTitle_succeeds() throws { }
func test_createCollection_withEmptyTitle_throwsError() throws { }
func test_indentNode_atMaxDepth_doesNotExceedLimit() throws { }
func test_buildTree_withFlatNodes_returnsCorrectHierarchy() throws { }
func test_visibleNodes_withCollapsedParent_excludesChildren() throws { }
```

---

## 14. 常见反例

| ❌ 错误写法 | ✅ 正确写法 | 原因 |
|---|---|---|
| `collectionId` | `collectionID` | Swift 官方约定，缩写全大写 |
| `pgTitle` | `pageTitle` | 禁止自创缩写 |
| `nodeArr` | `nodes` | 类型信息不重复，用复数 |
| `titleString` | `title` | 类型信息不重复 |
| `kDefaultDepth` | `defaultDepth` | Swift 不用 `k` 前缀 |
| `CollectionVM` | `CollectionListViewModel` | 禁止自创缩写 |
| `indenting` | `indent` / `indented` | 动词形式区分副作用意图 |
| `NodeEditorEng` | `NodeEditorEngine` | 禁止自创缩写 |
| `isCollapsedBool` | `isCollapsed` | 类型信息不重复 |
| `fetchData()` | `fetchCollections()` | 命名应包含语义 |
| `case Text` | `case text` | Swift 3+ 枚举 case 用 lowerCamelCase |

---

## 附录：Notte 核心类型速查

| 类型 | 文件 | 备注 |
|---|---|---|
| `Collection` | `Domain/Entities/Collection.swift` | 领域实体 |
| `Page` | `Domain/Entities/Page.swift` | 领域实体 |
| `Node` | `Domain/Entities/Node.swift` | 领域实体，flat storage |
| `Block` | `Domain/Entities/Block.swift` | 领域实体，开发者概念 |
| `BlockType` | `Domain/Entities/BlockType.swift` | 枚举，MVP 只有 `text` |
| `CollectionModel` | `Data/Models/CollectionModel.swift` | SwiftData @Model |
| `NodeEditorEngine` | `Features/NodeEditor/Engine/NodeEditorEngine.swift` | 树构建与命令调度 |
| `NodeMutationService` | `Features/NodeEditor/Engine/NodeMutationService.swift` | 结构变更 |
| `NodeQueryService` | `Features/NodeEditor/Engine/NodeQueryService.swift` | 树查询与可见性 |
| `BlockEditingService` | `Features/NodeEditor/Engine/BlockEditingService.swift` | 内容层变更 |
| `ColorTokens` | `Shared/Theme/ColorTokens.swift` | 设计 token |
| `TypographyTokens` | `Shared/Theme/TypographyTokens.swift` | 设计 token |
| `SpacingTokens` | `Shared/Theme/SpacingTokens.swift` | 设计 token |

---

> **一条记忆法则：**
> 
> - **类型** → UpperCamelCase，名词
> - **变量 / 方法** → lowerCamelCase，名词 / 动词
> - **布尔** → `is` / `has` / `can` 前缀
> - **枚举 case** → lowerCamelCase
> - **缩写** → 全大写（`ID`、`URL`、`UI`）或完全不缩写
> - **禁止** → 自创缩写、匈牙利命名、`k` 前缀
