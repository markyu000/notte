# Notte MVP 工程深化设计文档

Version: v1.0  
Scope: MVP Only  
Base Plan: 依据《Notte MVP 阶段开发计划与执行文档》进行工程深化  
Target Platforms: iPhone → iPad → macOS  
Tech Stack: SwiftUI + SwiftData + CloudKit  
Core Model: Collection → Page → Node

---

# 0. 文档目的

本文档不是产品介绍文档，而是 **MVP 阶段的工程执行文档**。  
目标是把已有的 MVP 计划，进一步落到：

- 业务逻辑如何建模
- 每个业务模块采用什么结构与架构
- 本地存储与同步采用什么方案
- Node 编辑器内部如何组织
- 各开发阶段的内部目标
- GitHub Project 应如何拆分 issue
- 每阶段完成后如何验收

本文档只服务于 **MVP 阶段**，不讨论 AI、协作、模板市场、复杂导出、Web、Notte Cloud 等后续能力。

---

# 1. MVP 总体工程原则

Notte MVP 的工程原则只有六条：

## 1.1 结构优先
Notte MVP 的核心价值是“结构化记录”，不是“富文本写作”，也不是“万能知识管理”。

因此所有设计都围绕这条主线：

```text
Collection
  └ Page
      └ Node Tree
          └ Block List
```

## 1.2 Local-first
MVP 必须先在单设备本地闭环成立。  
iCloud 是后半段增强能力，不是 MVP 成立前提。

## 1.3 简单模型优先
MVP 不做过度抽象。  
能用 `Collection / Page / Node / Block` 解决的问题，不再增加更高阶对象。

## 1.4 单一主路径优先
先保证最重要的主路径流畅：

```text
打开 App
→ 创建 Collection
→ 创建 Page
→ 创建 Node
→ 在 Node 中编辑 Block 内容
→ 调整 Node 结构
→ 退出重进仍保留
→ 可选跨设备同步
```

## 1.5 iPhone 先行
所有核心业务逻辑与交互，先在 iPhone 上完成。  
iPad 与 macOS 在后续阶段做共享与适配，不提前分散精力。

## 1.6 晚接入同步
本地模型、编辑器、持久化没稳定之前，不接入 CloudKit。

---

# 2. MVP 业务逻辑全景

MVP 阶段可以拆成 8 个业务逻辑域：

1. Collection 逻辑
2. Page 逻辑
3. Node 编辑逻辑
4. Node 结构变更逻辑
5. Block 编辑逻辑
6. 持久化逻辑
7. 同步逻辑
8. 首次引导与示例逻辑
9. 设置与反馈逻辑

它们之间的依赖关系如下：

```text
Onboarding / Settings
        ↓
Collections
        ↓
Pages
        ↓
Node Editor
  ├ Node Tree（结构层）
  └ Block Editor（内容层）
        ↓
Persistence
        ↓
Sync (optional beta)
```

其中，真正的核心只有四层：

```text
Collection Layer
Page Layer
Node Layer
Block Layer
```

---

# 3. 各业务逻辑采用的结构、架构与方案

---

# 3.1 Collection 业务逻辑设计

## 3.1.1 职责
Collection 是一级组织单位。  
MVP 中它承担三个职责：

- 作为首页的主要展示对象
- 承载若干 Page
- 作为结构化主题入口

## 3.1.2 数据结构方案
Collection 建议保持极简，字段如下：

```text
id: UUID
title: String
iconName: String?
colorToken: String?
createdAt: Date
updatedAt: Date
sortIndex: Double
isPinned: Bool
```

MVP 阶段不建议加入太多衍生字段，例如复杂统计、标签、权限、描述块等。

## 3.1.3 逻辑架构方案
Collection 模块采用：

```text
View
→ ViewModel
→ UseCase
→ Repository
→ SwiftData
```

原因：

- UI 层简单清晰
- 便于单元测试
- 便于后续替换持久化实现
- 不会把 SwiftUI 视图直接和数据模型强耦合

## 3.1.4 主要 UseCase
Collection 模块建议单独拆出这些 UseCase：

- CreateCollectionUseCase
- RenameCollectionUseCase
- DeleteCollectionUseCase
- PinCollectionUseCase
- ReorderCollectionsUseCase
- FetchCollectionsUseCase

## 3.1.5 排序方案
MVP 推荐使用 `sortIndex` 排序，不直接依赖数组下标。  
原因：

- 便于拖动排序
- 便于增量插入
- 后续同步冲突更容易处理

建议方案：

- 初始值每项间隔 1000
- 插入时取相邻值的中间值
- 定期在后台做 normalize

---

# 3.2 Page 业务逻辑设计

## 3.2.1 职责
Page 是 Collection 下的二级容器。  
MVP 阶段它承担：

- 页面内容的逻辑边界
- Node Tree 的宿主
- 用户最常进入的编辑入口

## 3.2.2 数据结构方案
Page 建议字段：

```text
id: UUID
collectionID: UUID
title: String
createdAt: Date
updatedAt: Date
sortIndex: Double
isArchived: Bool
```

MVP 不建议加入封面、复杂属性面板、模板继承信息等。

## 3.2.3 架构方案
Page 模块和 Collection 保持同样结构：

```text
View
→ ViewModel
→ UseCase
→ Repository
→ SwiftData
```

Page 层不要直接处理 Node Tree 细节。  
Page 的职责是：

- 加载页面基本信息
- 承接 NodeEditorContainer
- 管理页面级保存状态与导航状态

## 3.2.4 主要 UseCase
- CreatePageUseCase
- RenamePageUseCase
- DeletePageUseCase
- DuplicatePageUseCase
- ReorderPagesUseCase
- FetchPagesByCollectionUseCase

## 3.2.5 删除策略
MVP 建议使用“软删除接口预留 + 当前实现直接删除”的折中方案：

- 工程层预留 `deletedAt` 或删除封装
- MVP 实际行为仍可直接删除
- 便于未来恢复站和回收站能力接入

---

# 3.3 Node 编辑业务逻辑设计

## 3.3.1 职责
Node 是 MVP 最核心对象。  
Node 既是内容单元，也是结构单元。

MVP 中 Node 需要支持：

- 文本编辑
- 新增
- 删除
- 上下重排
- 缩进 / 反缩进
- 折叠 / 展开
- 基础类型渲染

## 3.3.2 数据结构方案

### Node 字段

```text
id: UUID
pageID: UUID
parentNodeID: UUID?
title: String          ← 大纲条目名，永远存在，大纲视图显示此字段
depth: Int             ← 同时决定缩进层级与标题渲染级别（对应 h1-h6，depth 0-5；depth 6+ 维持 h6 样式）
sortIndex: Double
isCollapsed: Bool
createdAt: Date
updatedAt: Date
```

**设计原则：**

- Node 是大纲条目（Outliner 模型），`title` 是条目名，永远不为空
- `depth` 统一承担缩进与标题级别两个职责，不单独设 `level` 字段，避免概念割裂
- depth 0 = h1，depth 1 = h2，…，depth 5 = h6；depth 超过 5 时维持 h6 样式，只增加缩进距离
- Node 不再有 `type` 字段，类型语义由 depth 和其下的 Block 决定
- Node 可以没有任何 Block（纯大纲条目），也可以挂载多个 Block（带内容的条目）

### Block 字段

```text
id: UUID
nodeID: UUID
type: BlockType
content: String        ← MVP 阶段：text 类型存正文；image/code 类型存路径或代码字符串
sortIndex: Double
createdAt: Date
updatedAt: Date
```

BlockType MVP 阶段只保留：

```text
text    ← 正文段落
```

BlockType POST 阶段按需扩展：

```text
bullet  ← 列表项样式（圆点）
image   ← content 存图片路径或 asset ID
code    ← content 存代码字符串，附加 language 元数据（可用 JSON 存入 content）
quote   ← 引用段落样式
```

**Block 与 Node 的职责边界：**

- Node 负责大纲结构（折叠、缩进、拖动、排序），这些操作只操作 Node 树
- Block 负责内容表达（文字、图片、代码），不参与结构操作
- 所有类型的 Node 折叠/拖动/缩进行为完全一致，Block 类型不影响结构操作逻辑

## 3.3.3 架构方案
Node 编辑器不要只用一个"大 ViewModel"。  
推荐拆成如下层次：

```text
PageEditorView
→ PageEditorViewModel
→ NodeEditorEngine
→ NodeMutationService / NodeQueryService / BlockEditingService
→ Repository
```

其中：

### PageEditorView
负责页面组装与事件分发，不承担复杂树操作。

### PageEditorViewModel
负责：
- 页面状态
- 当前 Node 列表的展示状态
- 选中态 / 编辑态
- 与页面级工具条交互

### NodeEditorEngine
负责：
- Node Tree 构建
- 结构变更命令调度
- 折叠 / 展开后的可见性计算
- 将存储模型转为编辑器可渲染模型（EditorNode）

### NodeMutationService
负责 Node 结构层变更：
- Insert
- Delete
- Move
- Indent
- Outdent
- Merge
- Split

### NodeQueryService
负责：
- 构建树
- 展平树
- 计算可见节点
- 查找前后兄弟与父子关系

### BlockEditingService
负责 Block 内容层变更：
- 在指定 Node 下新增 Block
- 删除 Block
- 重排 Block 顺序（调整 sortIndex）
- 更新 Block content
- MVP 阶段只处理 text 类型；POST 阶段扩展 image / code 等类型
## 3.3.4 为什么不把所有逻辑写进 ViewModel
因为 Node Editor 会很快变复杂。  
如果把树结构操作、光标逻辑、折叠状态、保存逻辑全堆到 ViewModel：

- 测试困难
- 视图刷新逻辑混乱
- 修改一个操作会影响多个交互
- 后续接入快捷键和多平台适配时会爆炸

---

# 3.4 Node 结构变更方案

Node 结构操作是 MVP 最关键的内部逻辑，建议采用“命令式变更模型”。

## 3.4.1 命令模型
定义统一的编辑命令，分为 Node 结构命令和 Block 内容命令两组：

**Node 结构命令：**

```text
insertAfter(nodeID)
insertChild(nodeID)
delete(nodeID)
moveUp(nodeID)
moveDown(nodeID)
indent(nodeID)
outdent(nodeID)
toggleCollapse(nodeID)
updateTitle(nodeID, title)
```

**Block 内容命令：**

```text
addBlock(nodeID, type)
deleteBlock(blockID)
updateBlockContent(blockID, content)
reorderBlock(blockID, newSortIndex)
```

这样做的好处：

- 结构操作与内容操作职责清晰，不混在同一命令集
- 所有编辑行为统一入口
- 好做日志与调试
- 好做单元测试
- 后续快捷键绑定更容易
## 3.4.2 树结构存储方案
MVP 推荐采用：

```text
Node：parentNodeID + sortIndex + depth
Block：nodeID + sortIndex
```

而不是完全嵌套对象持久化。  
原因：

- SwiftData 更适合扁平持久化
- 查询和排序更稳定
- 结构变更后只需更新局部字段
- Block 与 Node 独立持久化，互不干扰
- 同步更容易
## 3.4.3 编辑器展示模型方案
持久化是扁平的。  
编辑器内部要构建：

```text
EditorNode
- id
- parentID
- depth
- title
- visible
- isCollapsed
- children: [EditorNode]
- blocks: [EditorBlock]   ← 该 Node 下的内容块，按 sortIndex 排列
```

```text
EditorBlock
- id
- type: BlockType
- content: String
```

即：

- **存储模型**：Node 扁平存储，Block 按 nodeID 关联
- **运行时模型**：Node 树 + 可见性状态 + 每个节点携带其 Block 列表
## 3.4.4 插入方案
推荐行为：

- 回车默认 `insertAfter(currentNode)`，新节点自动创建一个空 text Block
- 若当前节点 title 为空且按退格，可触发删除 / 反缩进逻辑
- 新节点继承当前 depth

## 3.4.5 缩进方案
`indent(node)` 行为：

- 当前节点成为前一个同级节点的最后一个子节点
- 更新 `parentNodeID`
- 更新 `depth`（同时影响该节点的标题渲染级别）
- 必要时调整 `sortIndex`

## 3.4.6 反缩进方案
`outdent(node)` 行为：

- 当前节点提升到父节点的同级
- `parentNodeID` 指向祖父节点
- `depth - 1`（同时影响该节点的标题渲染级别）
- 排序插入到原父节点后面
## 3.4.7 删除方案
MVP 推荐：

- 删除父节点时，默认同时删除全部子节点
- 不做复杂“提升子节点”策略
- 行为更直观，也更容易实现

---

# 3.5 持久化逻辑设计

## 3.5.1 持久化目标
MVP 持久化只需满足：

- 本地可靠保存
- 重启后恢复
- 异常中断后尽量少丢数据
- 为同步预留结构

## 3.5.2 技术方案
推荐：

```text
SwiftData 作为主持久化
Repository 封装读写
```

## 3.5.3 保存策略
Node 编辑器不建议每敲一个字就立刻做重度存储操作。  
建议采用：

- UI 层实时更新内存状态
- 短间隔 debounce 自动保存
- 页面退出时强制 flush
- App 进入后台时强制 flush

## 3.5.4 Repository 结构
建议拆为：

- CollectionRepository
- PageRepository
- NodeRepository
- BlockRepository

不要搞一个全能大仓库。  
否则后续模块边界会越来越模糊。
## 3.5.5 事务边界
以下操作建议做成"单次事务"：

- 删除 Page 及其全部 Node 和 Block
- 删除 Collection 及其全部 Page / Node / Block
- 删除 Node 及其全部子 Node 和对应 Block
- 缩进 / 反缩进导致的多节点批量更新
- 重排序后的 normalize
---

# 3.6 同步逻辑设计

## 3.6.1 MVP 同步原则
同步在 MVP 中不是核心价值源头，而是增强项。  
所以同步策略必须保守。

## 3.6.2 方案
推荐：

```text
SwiftData + CloudKit
```

但只有在以下条件满足后接入：

- Collection / Page / Node 本地闭环已稳定
- Node 编辑器核心行为已测试通过
- 数据模型字段基本稳定

## 3.6.3 同步阶段策略
建议同步分三段：

### 阶段 A
只做本地，不开 CloudKit。

### 阶段 B
接入 CloudKit 容器，但只做基础推拉。

### 阶段 C
加入同步状态展示和最基本冲突兜底。

## 3.6.4 冲突方案
MVP 采用：

```text
Last Write Wins
```

不要在 MVP 做复杂合并。  
理由：

- 开发成本高
- 行为难以解释
- 测试量会显著膨胀

## 3.6.5 同步状态可视化
MVP 不需要复杂同步中心。  
但建议提供：

- 设置页中的同步开关 / 状态文本
- 调试模式的同步日志页
- 同步失败时简短提示

---

# 3.7 Onboarding 与示例逻辑设计

## 3.7.1 目标
Onboarding 的目标不是讲完整产品，而是让用户 3 分钟内知道该怎么开始。

## 3.7.2 结构方案
建议 3 屏结构：

### 第 1 屏
Notte 是什么  
强调“结构化整理”

### 第 2 屏
Collection / Page / Node 是什么  
用一个简单图示说明

### 第 3 屏
直接开始  
提供：
- 创建空 Collection
- 导入示例数据

## 3.7.3 示例数据方案
MVP 强烈建议内置 2~3 套示例：

- SwiftUI 学习
- 项目规划
- 读书笔记

示例不是装饰，而是产品“啊哈时刻”的一部分。

---

# 3.8 设置与反馈逻辑设计

MVP 设置页不要做成大杂烩。  
建议只包含：

- iCloud 同步状态
- 深浅色模式跟随系统说明
- 版本号
- 反馈入口
- 关于 Notte
- 调试菜单（仅 debug）

---

# 4. MVP 工程架构总图

推荐整体分层如下：

```text
App
├── AppBootstrap
├── AppRouter
├── DependencyContainer
│
Features
├── Collections
├── Pages
├── NodeEditor
├── Onboarding
├── Settings
│
Domain
├── Entities
├── UseCases
├── Services
│
Data
├── Repositories
├── Persistence
├── Sync
│
Shared
├── Components
├── Theme
├── Utilities
│
Infrastructure
├── Logging
├── Analytics
├── DebugTools
```

---

# 5. 推荐目录结构

```text
Notte/
├── App/
│   ├── NotteApp.swift
│   ├── AppBootstrap.swift
│   ├── AppRouter.swift
│   └── DependencyContainer.swift
│
├── Features/
│   ├── Collections/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── UseCases/
│   │   └── Components/
│   │
│   ├── Pages/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── UseCases/
│   │   └── Components/
│   │
│   ├── NodeEditor/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Engine/
│   │   ├── Commands/
│   │   ├── Services/
│   │   └── Components/
│   │
│   ├── Onboarding/
│   └── Settings/
│
├── Domain/
│   ├── Entities/
│   ├── Enums/
│   ├── Protocols/
│   └── Services/
│
├── Data/
│   ├── Models/
│   ├── Repositories/
│   ├── Persistence/
│   └── Sync/
│
├── Shared/
│   ├── Components/
│   ├── Theme/
│   ├── Extensions/
│   └── Utilities/
│
├── Infrastructure/
│   ├── Logging/
│   ├── Analytics/
│   └── Debug/
│
└── Docs/
```

---

# 6. 开发阶段划分

整个 MVP 建议拆为 8 个阶段。

---

# 阶段 1：定义冻结与工程底座

## 目标
完成：

- MVP 范围冻结
- 仓库初始化
- 分支策略
- 工程目录
- Theme tokens
- SwiftData container
- Core Models
- 基础日志和错误处理

## GitHub Project 建议 issue

### Docs / Planning
- Define MVP scope
- Define out-of-scope list
- Define core user journey
- Define project naming rules
- Define issue template
- Define PR template
- Define branch strategy

### Engineering Foundation
- Bootstrap Xcode project
- Setup app entry point
- Setup app router shell
- Setup dependency container
- Setup theme tokens
- Setup color tokens
- Setup typography tokens
- Setup spacing tokens
- Setup logger abstraction
- Setup error presentation helper
- Setup debug menu shell

### Data Foundation
- Create SwiftData container
- Create Collection model
- Create Page model
- Create Node model
- Define NodeType enum
- Define sortIndex policy
- Create repository protocols
- Create repository skeletons
- Add foundation smoke tests

## 验收
- 工程可运行
- 数据模型可编译
- 本地容器正常初始化
- 首页壳子可打开
- 调试菜单可用
- 基础 token 与组件规范明确

---

# 阶段 2：Collection 模块完成

## 目标
完成首页结构与 Collection 的基本管理。

## GitHub Project 建议 issue

### Domain
- Implement create collection use case
- Implement rename collection use case
- Implement delete collection use case
- Implement pin collection use case
- Implement reorder collection use case
- Implement fetch collections use case

### UI
- Build collection list screen
- Build collection card
- Build collection empty state
- Build collection create sheet
- Build collection rename sheet
- Build collection delete dialog
- Build collection loading state
- Build collection context menu
- Build collection pinned indicator

### ViewModel
- Create CollectionListViewModel
- Add initial load flow
- Add create flow
- Add rename flow
- Add delete flow
- Add pin flow
- Add reorder flow
- Add collection analytics events

### Test
- Add collection repository tests
- Add collection use case tests
- Add collection UI flow tests

## 验收
- 首页能显示 Collection 列表
- 用户可创建、重命名、删除、固定 Collection
- 排序结果能持久化
- 空状态清晰
- 首次使用不迷失

---

# 阶段 3：Page 模块完成

## 目标
进入 Collection 后，Page 层逻辑完整成立。

## GitHub Project 建议 issue

### Domain
- Implement create page use case
- Implement rename page use case
- Implement delete page use case
- Implement duplicate page use case
- Implement reorder page use case
- Implement fetch pages by collection use case

### UI
- Build page list screen
- Build page row
- Build page empty state
- Build page create sheet
- Build page rename sheet
- Build page delete dialog
- Build page duplicate action
- Build page reorder interaction

### ViewModel
- Create PageListViewModel
- Add page load flow
- Add page create flow
- Add page rename flow
- Add page delete flow
- Add page duplicate flow
- Add page reorder flow
- Add page analytics events

### Test
- Add page repository tests
- Add page use case tests
- Add page flow UI tests

## 验收
- 从 Collection 能正常进入 Page 列表
- Page 的增删改查、复制、排序成立
- Page 层导航稳定
- 大量 Page 时无明显卡顿

---

# 阶段 4：Node Editor Core 完成

## 目标
完成 Node 编辑器核心闭环。  
这是 MVP 最关键阶段。

## GitHub Project 建议 issue

### Engine
- Create NodeEditorEngine
- Create EditorNode runtime model
- Implement build node tree
- Implement flatten visible nodes
- Implement toggle collapse command
- Implement update content command
- Implement insert after command
- Implement insert child command
- Implement delete node command
- Implement move up command
- Implement move down command
- Implement indent command
- Implement outdent command
- Implement normalize sortIndex helper

### Services
- Create NodeMutationService
- Create NodeQueryService
- Create NodeVisibilityService
- Create NodePersistenceCoordinator

### UI
- Build page editor container
- Build node row
- Build node content editor
- Build node indentation guides
- Build node collapse control
- Build node type indicator
- Build add-node interaction
- Build delete-node interaction

### ViewModel
- Create PageEditorViewModel
- Load page editor data
- Bind visible editor nodes
- Dispatch editor commands
- Handle autosave state
- Handle editor error state

### Tests
- Add node tree build tests
- Add insert command tests
- Add delete command tests
- Add indent tests
- Add outdent tests
- Add move tests
- Add collapse visibility tests

## 验收
- 用户可以输入 Node 文本
- 可以新增、删除、缩进、反缩进、上下移动 Node
- 折叠 / 展开正常
- 重启后数据仍存在
- 结构不乱
- 页面基本可用

---

# 阶段 5：Node Editor UX 补齐

## 目标
让 Node 编辑器从“能用”升级为“顺手”。

## GitHub Project 建议 issue

### Editing UX
- Add debounce autosave
- Add save on background flush
- Add save on page exit flush
- Add node focus state
- Add current row highlight
- Add keyboard return insertion behavior
- Add backspace empty-node behavior
- Add toolbar shell
- Add lightweight editing feedback
- Add long-note scroll optimization

### Visual UX
- Improve node row spacing
- Improve indentation visual hierarchy
- Improve collapse animation
- Improve selected row readability
- Improve editor empty page state

### Tests
- Add autosave tests
- Add focus transition tests
- Add long page performance tests
- Add page exit save tests

## 验收
- 长页面编辑体验不崩
- 自动保存策略可靠
- 回车与删除行为符合直觉
- 编辑器层级感清晰
- 基础体验明显优于阶段 4

---

# 阶段 6：Onboarding、示例数据、设置页

## 目标
完成首次体验闭环，而不是只有一个空壳。

## GitHub Project 建议 issue

### Onboarding
- Build onboarding page 1
- Build onboarding page 2
- Build onboarding page 3
- Add skip onboarding action
- Add continue onboarding action
- Add first-run state persistence

### Example Data
- Create example collection factory
- Create SwiftUI learning example
- Create project planning example
- Create reading notes example
- Add import example data action

### Settings
- Build settings screen
- Build iCloud sync status section
- Build version info section
- Build feedback entry
- Build about page
- Add debug-only settings section

### Tests
- Add onboarding flow UI tests
- Add example data import tests
- Add first-run persistence tests

## 验收
- 新用户首次打开不会看到完全空白
- 3 分钟内可理解核心模型
- 可快速创建首个 Collection 或导入示例
- 设置页可用且简洁

---

# 阶段 7：iCloud Sync Beta

## 目标
在本地闭环稳定后，接入最小可用同步。

## GitHub Project 建议 issue

### Sync Foundation
- Configure CloudKit container
- Enable SwiftData cloud sync
- Add sync environment config
- Add sync logger
- Add sync error mapping

### Sync UX
- Add sync status text
- Add sync failure hint
- Add debug sync diagnostics
- Add manual refresh debug action

### Conflict Policy
- Implement last-write-wins policy wrapper
- Document sync conflict assumptions
- Add sync-safe save timing rules

### Tests
- Add device A create device B sync test
- Add rename sync test
- Add delete sync test
- Add page node sync test
- Add offline then reconnect test

## 验收
- 两设备基础同步可用
- 同步失败不会破坏本地主数据
- 同步状态有最小可见性
- 本地主路径仍成立
- 不因同步接入导致编辑器大规模回归

---

# 阶段 8：UI Polish、测试、封版发布

## 目标
完成 MVP 的视觉统一、稳定性提升和 TestFlight 发布准备。

## GitHub Project 建议 issue

### UI Polish
- Polish collection card visuals
- Polish page row visuals
- Polish node row visuals
- Add dark mode verification
- Improve spacing consistency
- Improve typography consistency
- Polish empty states
- Polish delete confirmations

### QA
- Create MVP regression checklist
- Run collection regression tests
- Run page regression tests
- Run editor regression tests
- Run sync regression tests
- Run small-screen layout checks
- Run dynamic type checks
- Run crash path checks

### Release
- Prepare release notes
- Prepare TestFlight checklist
- Prepare feedback form
- Prepare demo script
- Prepare App Store screenshot list
- Freeze MVP feature scope

## 验收
- 主路径无阻塞 Bug
- 深浅色模式可用
- 主要页面视觉统一
- TestFlight 版可安装、可演示、可收集反馈
- 有明确的下一阶段 backlog

---

# 7. GitHub Project 推荐看板

推荐列：

```text
Backlog
Planned
Ready
In Progress
Blocked
Review
QA
Done
```

推荐 Milestone：

```text
M0 Definition
M1 Foundation
M2 Collections
M3 Pages
M4 Node Editor Core
M5 Node Editor UX
M6 Onboarding & Settings
M7 Sync Beta
M8 QA & Release
```

推荐 Labels：

### 模块
```text
area/app
area/collection
area/page
area/node-editor
area/persistence
area/sync
area/ui
area/onboarding
area/settings
area/release
area/testing
```

### 类型
```text
type/feature
type/bug
type/refactor
type/test
type/docs
type/chore
```

### 优先级
```text
priority/p0
priority/p1
priority/p2
```

### 平台
```text
platform/shared
platform/ios
platform/ipad
platform/macos
```

---

# 8. 多平台开发策略

## 8.1 iPhone 阶段
先完成所有业务逻辑闭环。  
这是 MVP 唯一必须先打透的平台。

## 8.2 iPad 阶段
在共享组件和编辑器主逻辑稳定后做：

- 更宽布局
- Sidebar / split view 优化
- 更舒展的 Page / Editor 展示

但不在 MVP 早期提前做复杂双栏交互。

## 8.3 macOS 阶段
MVP 阶段只做“基础可用”：

- 能查看 Collection / Page
- 能进入页面编辑
- 核心 Node 编辑逻辑可复用

不做高级菜单命令体系，不做复杂多窗口策略。

---

# 9. 阶段性验收总表

## 阶段 1 验收
- 工程底座成立
- SwiftData 可用
- 模型清晰
- 主题 token 已定义

## 阶段 2 验收
- Collection 主路径成立
- 首页可用

## 阶段 3 验收
- Page 主路径成立
- Collection → Page 流程稳定

## 阶段 4 验收
- Node 编辑器核心功能成立
- 结构不乱
- 数据能持久化

## 阶段 5 验收
- 编辑器顺手
- 自动保存可靠
- 长页面可用

## 阶段 6 验收
- 首次使用不迷失
- 示例数据帮助理解价值
- 设置页完整

## 阶段 7 验收
- iCloud Beta 可用
- 不破坏本地闭环

## 阶段 8 验收
- 可 TestFlight
- 可演示
- 可收集反馈

---

# 10. 最终 MVP 完成定义

只有当下面条件全部满足时，才算 MVP 完成：

```text
1. 用户可创建 Collection
2. 用户可在 Collection 中创建 Page
3. 用户可在 Page 中创建并编辑 Node
4. 用户可调整 Node 层级与顺序
5. 数据本地持久化可靠
6. 首次引导与示例数据可用
7. iCloud Beta 基本可用或具备明确开关
8. 应用可用于 TestFlight 小范围测试
```

---

# 11. 结论

Notte 的 MVP，不是一个“小型 Notion”，也不是“更漂亮的 Apple Notes”。

它在工程上必须始终围绕一条主线推进：

```text
Collection → Page → Node
```

因此工程优先级必须固定为：

```text
先数据模型
→ 再 Collection / Page
→ 再 Node Editor Core
→ 再 Editor UX
→ 再 Onboarding
→ 最后 Sync Beta 与 QA Release
```

任何脱离这条链路的能力，都不应进入 MVP。
