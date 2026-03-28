# Notte 项目目录结构说明

> 本文档覆盖从 MVP 阶段到完整版的全开发生命周期。  
> 每个目录标注了所属阶段：**[MVP]** / **[POST]** / **[INFRA]**

---

## 阶段标注说明

| 标注 | 含义 |
|------|------|
| `[MVP]` | MVP 阶段必须完成，是核心闭环的一部分 |
| `[POST]` | MVP 之后版本（v0.2+）引入，MVP 阶段可不实现但需预留接口 |
| `[INFRA]` | 工程基础设施，贯穿所有阶段，早期可简化实现 |

---

## 完整目录树

```
Notte/
├── App/                              [MVP]
│   ├── NotteApp.swift
│   ├── AppBootstrap.swift
│   ├── AppRouter.swift
│   └── DependencyContainer.swift
│
├── Features/
│   ├── Onboarding/                   [MVP]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   │
│   ├── Collections/                  [MVP]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── UseCases/
│   │   └── Components/
│   │
│   ├── Pages/                        [MVP]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── UseCases/
│   │   └── Components/
│   │
│   ├── NodeEditor/                   [MVP]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Engine/
│   │   ├── Commands/
│   │   ├── Services/
│   │   │   ├── NodeMutationService.swift
│   │   │   ├── NodeQueryService.swift
│   │   │   ├── NodeVisibilityService.swift
│   │   │   ├── NodePersistenceCoordinator.swift
│   │   │   └── BlockEditingService.swift
│   │   └── Components/
│   │
│   ├── Settings/                     [MVP]
│   │   ├── Views/
│   │   └── ViewModels/
│   │
│   ├── Search/                       [POST]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Services/
│   │
│   ├── Templates/                    [POST]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Library/
│   │   └── Models/
│   │
│   ├── MapView/                      [POST]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Adapters/
│   │
│   ├── Collaboration/                [POST]
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Services/
│   │
│   ├── Export/                       [POST]
│   │   ├── Views/
│   │   ├── Formatters/
│   │   └── Services/
│   │
│   └── AI/                           [POST]
│       ├── Views/
│       ├── ViewModels/
│       └── Services/
│
├── Domain/                           [MVP]
│   ├── Entities/
│   │   ├── Collection.swift
│   │   ├── Page.swift
│   │   ├── Node.swift
│   │   ├── Block.swift
│   │   └── BlockType.swift
│   ├── Enums/
│   ├── Protocols/
│   └── Services/
│
├── Data/
│   ├── Models/                       [MVP]
│   │   ├── CollectionModel.swift
│   │   ├── PageModel.swift
│   │   ├── NodeModel.swift
│   │   └── BlockModel.swift
│   ├── Repositories/                 [MVP]
│   │   ├── CollectionRepository.swift
│   │   ├── PageRepository.swift
│   │   ├── NodeRepository.swift
│   │   └── BlockRepository.swift
│   ├── Persistence/                  [MVP]
│   │   ├── PersistenceController.swift
│   │   └── MigrationPlan.swift
│   ├── Sync/                         [MVP - Beta后半段]
│   │   ├── CloudKitSyncEngine.swift
│   │   └── SyncConflictPolicy.swift
│   ├── Cloud/                        [POST]
│   │   ├── NotteCloudClient.swift
│   │   └── CollaborationEngine.swift
│   └── Export/                       [POST]
│       ├── MarkdownExporter.swift
│       ├── PDFExporter.swift
│       └── MindMapExporter.swift
│
├── Shared/                           [MVP]
│   ├── Components/
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   ├── EmptyStateView.swift
│   │   ├── DeleteConfirmDialog.swift
│   │   ├── SectionHeader.swift
│   │   ├── CollectionCard.swift
│   │   ├── PageRow.swift
│   │   ├── NodeRow.swift
│   │   └── InputSheet.swift
│   ├── Theme/
│   │   ├── ColorTokens.swift
│   │   ├── TypographyTokens.swift
│   │   └── SpacingTokens.swift
│   ├── Extensions/
│   └── Utilities/
│
├── Platform/
│   ├── iPhone/                       [MVP]
│   │   └── iPhoneAdaptations.swift
│   ├── iPad/                         [POST]
│   │   ├── SplitViewController.swift
│   │   └── iPadAdaptations.swift
│   └── macOS/                        [POST]
│       ├── MenuBarCommands.swift
│       └── macOSAdaptations.swift
│
├── Infrastructure/                   [INFRA]
│   ├── Logging/
│   ├── Analytics/
│   ├── FeatureFlags/
│   └── Debug/
│
├── Resources/                        [MVP]
│   ├── Assets.xcassets/
│   ├── SampleData/
│   │   ├── SwiftUILearning.json
│   │   ├── ProjectPlanning.json
│   │   └── ReadingNotes.json
│   └── Localizations/
│
├── Tests/                            [INFRA]
│   ├── UnitTests/
│   ├── IntegrationTests/
│   └── UITests/
│
└── Docs/                             [MVP]
    ├── Architecture.md
    ├── DataModel.md
    └── Changelog.md
```

---

## 各层详细说明

---

### `App/` — 应用入口层 [MVP]

应用的顶层引导逻辑，所有模块在此装配。

| 文件 | 职责 |
|------|------|
| `NotteApp.swift` | SwiftUI App 入口，场景配置 |
| `AppBootstrap.swift` | 启动时初始化：SwiftData 容器、示例数据注入、Feature Flag 加载 |
| `AppRouter.swift` | 全局导航状态管理，路由 Collection → Page → NodeEditor |
| `DependencyContainer.swift` | 依赖注入容器，统一管理 Repository、UseCase、Service 的生命周期 |

---

### `Features/` — 功能模块层

按功能域垂直切分，每个子模块内部均遵循 `Views / ViewModels / UseCases / Components` 的分层结构。

---

#### `Features/Onboarding/` [MVP]

首次启动引导，目标是让用户 3 分钟内理解 Collection / Page / Node / Block 模型。

- `Views/`：三屏引导页（产品定位 → 结构模型图示 → 直接开始）
- `ViewModels/`：引导状态、跳过逻辑、首次使用标记持久化
- `Components/`：引导卡片组件、进度指示器

设计原则：不超过 3 屏，末屏提供"创建空 Collection"或"导入示例数据"两个入口。

---

#### `Features/Collections/` [MVP]

首页核心模块，用户与产品交互的第一个屏幕。

- `Views/`：Collection 列表页、空状态页
- `ViewModels/`：CollectionListViewModel，管理加载、创建、删除、排序、Pin 状态
- `UseCases/`：
  - `CreateCollectionUseCase`
  - `RenameCollectionUseCase`
  - `DeleteCollectionUseCase`
  - `PinCollectionUseCase`
  - `ReorderCollectionsUseCase`
  - `FetchCollectionsUseCase`
- `Components/`：CollectionCard、CollectionContextMenu、PinIndicator

排序策略：使用浮点 `sortIndex`，初始间隔 1000，插入时取相邻中间值，后台定期 normalize。

---

#### `Features/Pages/` [MVP]

进入 Collection 后的二级页面管理模块。

- `Views/`：Page 列表页、Page 空状态
- `ViewModels/`：PageListViewModel
- `UseCases/`：
  - `CreatePageUseCase`
  - `RenamePageUseCase`
  - `DeletePageUseCase`
  - `DuplicatePageUseCase`
  - `ReorderPagesUseCase`
  - `FetchPagesByCollectionUseCase`
- `Components/`：PageRow、PageContextMenu

删除策略：工程层预留软删除接口（`deletedAt`），MVP 实现可直接删除，为后续回收站能力预留。

---

#### `Features/NodeEditor/` [MVP]

MVP 最复杂、最核心的模块。Node 编辑器采用五层结构：

```
PageEditorView
→ PageEditorViewModel
→ NodeEditorEngine
→ NodeMutationService / NodeQueryService
→ NodeRepository
```

- `Views/`：PageEditorView、NodeRow、NodeContentEditor、折叠控件
- `ViewModels/`：PageEditorViewModel（管理页面状态、可见节点列表、选中态、自动保存）
- `Engine/`：NodeEditorEngine（树构建、可见性计算、运行时 EditorNode 模型）
- `Commands/`：统一命令模型
  - Node 结构命令：`insertAfter` / `insertChild` / `delete` / `moveUp` / `moveDown` / `indent` / `outdent` / `toggleCollapse` / `updateTitle`
  - Block 内容命令：`addBlock` / `deleteBlock` / `updateBlockContent` / `reorderBlock`
- `Services/`：
  - `NodeMutationService`：执行 Node 结构变更
  - `NodeQueryService`：树查询、可见节点展平、父子关系查找
  - `NodeVisibilityService`：折叠展开后可见性计算
  - `BlockEditingService`：Block 的增删改排，MVP 只处理 text 类型
  - `NodePersistenceCoordinator`：debounce 自动保存、退出/后台强制 flush
- `Components/`：缩进指示线、深度标题渲染（h1-h6）、新增 Node 交互控件

存储模型：Node 扁平（`parentNodeID + sortIndex + depth`）；Block 按 `nodeID + sortIndex` 关联。  
运行时模型：树形 `EditorNode`（含 `title`、`depth`、`children`、`visible`、`isCollapsed`、`blocks: [EditorBlock]`）。  
保存策略：UI 层实时更新内存 → 短间隔 debounce → 退出/后台强制 flush。

---

#### `Features/Settings/` [MVP]

设置页，保持极简，不做大杂烩。

内容只包含：iCloud 同步状态、深浅色模式跟随说明、版本号、反馈入口、关于 Notte、调试菜单（仅 Debug 构建可见）。

---

#### `Features/Search/` [POST]

全局搜索模块，以 Node 为最小搜索单位。

- `Services/`：本地索引构建（SwiftData 全文搜索），以 Node title 和 Block content 为索引目标
- 支持按标题、内容分别搜索
- 支持 Page 内文本定位

---

#### `Features/Templates/` [POST]

模板系统，分三层：Node 模板 / Page 模板 / Collection 模板。

- `Library/`：内置模板包（SwiftUI 学习、项目规划、读书笔记等）
- `Models/`：TemplateDefinition、TemplateCategory
- 后期支持模板上传、下载、社区分享

---

#### `Features/MapView/` [POST]

思维导图视图，与 Outline View 无缝切换。

- `Adapters/`：将 Node Tree 转换为思维导图渲染数据
- 支持在同一窗口内切换大纲/导图两种视图
- 支持导出思维导图为图片/PDF

---

#### `Features/Collaboration/` [POST]

协作功能，支持三个粒度：Page 级协作、Node 级评论与修改、Collection 级共享。

依赖 `Data/Cloud/` 的 Notte Cloud 层，MVP 阶段不实现。

---

#### `Features/Export/` [POST]

内容导出能力。

- `Formatters/`：Markdown、PDF、富文本格式化器
- `Services/`：导出任务调度
- 支持：Markdown 导入导出、PDF/图片大纲导出、思维导图图片导出

---

#### `Features/AI/` [POST]

AI 增强能力，作为中后期增强项，不进入 MVP 主轴。

计划能力：结构建议、摘要生成、语义关联、内容润色。  
MVP 阶段只需在此目录占位，不实现任何逻辑。

---

### `Domain/` — 业务领域层 [MVP]

纯 Swift 业务逻辑，不依赖任何 UI 或存储框架。

#### `Entities/`

| 文件 | 核心字段 |
|------|----------|
| `Collection.swift` | id, title, iconName, colorToken, sortIndex, isPinned, createdAt, updatedAt |
| `Page.swift` | id, collectionID, title, sortIndex, isArchived, createdAt, updatedAt |
| `Node.swift` | id, pageID, parentNodeID, title, depth, sortIndex, isCollapsed, createdAt, updatedAt |
| `Block.swift` | id, nodeID, type, content, sortIndex, createdAt, updatedAt |
| `BlockType.swift` | text（MVP）；bullet / image / code / quote（POST）|

#### `Protocols/`

Repository 协议定义，便于测试时替换 Mock 实现，也为未来替换持久化方案预留。

---

### `Data/` — 数据层

#### `Models/` [MVP]

SwiftData `@Model` 类，与 Domain Entities 保持映射关系，不直接暴露给 UI 层。

#### `Repositories/` [MVP]

封装所有 SwiftData 读写操作。独立拆分为四个 Repository，避免单一大仓库导致边界模糊：

- `CollectionRepository`
- `PageRepository`
- `NodeRepository`
- `BlockRepository`

事务边界：删除 Page 及其全部 Node 和 Block、删除 Collection 及其全部内容、删除 Node 及其子 Node 和对应 Block、缩进/反缩进批量更新，均作为单次事务处理。

#### `Persistence/` [MVP]

- `PersistenceController.swift`：SwiftData container 初始化，管理本地存储
- `MigrationPlan.swift`：Schema 版本迁移计划，从第一版起就建立，避免后续数据模型变更破坏用户数据

#### `Sync/` [MVP - Beta 后半段]

iCloud 同步，在本地闭环稳定后接入。

- `CloudKitSyncEngine.swift`：SwiftData + CloudKit 桥接，按阶段 A（仅本地）→ B（基础推拉）→ C（状态展示）推进
- `SyncConflictPolicy.swift`：MVP 采用 Last Write Wins，不做复杂合并

#### `Cloud/` [POST]

Notte Cloud 自建云层，用于支持协作、跨平台、AI 服务。MVP 阶段完全不实现。

#### `Export/` [POST]

导出服务实现层，与 `Features/Export/` 配合使用。

---

### `Shared/` — 共享组件层 [MVP]

跨功能模块复用的 UI 组件和设计 token，确保全产品视觉一致性。

#### `Components/`

MVP 阶段必须统一的基础组件：

| 组件 | 用途 |
|------|------|
| `PrimaryButton` | 主操作按钮 |
| `SecondaryButton` | 次操作按钮 |
| `EmptyStateView` | 空状态通用占位 |
| `DeleteConfirmDialog` | 删除确认弹窗 |
| `SectionHeader` | 列表分区标题 |
| `CollectionCard` | Collection 卡片 |
| `PageRow` | Page 列表行 |
| `NodeRow` | Node 编辑行（含标题渲染 h1-h6、深度缩进指示、Block 内容区） |
| `InputSheet` | 底部输入弹窗 |

#### `Theme/`

设计 token 集中管理，避免散落在各视图中：

- `ColorTokens`：浅色/深色模式下的语义颜色（主色、背景、强调、危险等）
- `TypographyTokens`：字号、字重、行高规范
- `SpacingTokens`：间距规范

---

### `Platform/` — 多平台适配层

按 iPhone → iPad → macOS 优先级推进。

| 子目录 | 阶段 | 说明 |
|--------|------|------|
| `iPhone/` | MVP | 所有核心业务逻辑先在 iPhone 完成 |
| `iPad/` | POST | 更宽布局、Sidebar/SplitView、更舒展的 Page/Editor 展示 |
| `macOS/` | POST | 菜单栏命令、多窗口策略，MVP 阶段只做"基础可用" |

iPad 和 macOS 的核心编辑逻辑复用 `Features/NodeEditor/Engine/`，只在此层做平台级适配。

---

### `Infrastructure/` — 工程基础设施 [INFRA]

| 子目录 | 职责 |
|--------|------|
| `Logging/` | 统一日志抽象，支持 Debug/Release 不同输出级别 |
| `Analytics/` | 关键转化事件埋点（激活、留存、付费转化节点），MVP 可用轻量实现 |
| `FeatureFlags/` | 功能开关，用于灰度上线和 A/B 测试 |
| `Debug/` | 调试菜单、同步日志页、示例数据注入工具（仅 Debug 构建） |

---

### `Resources/` — 静态资源 [MVP]

#### `SampleData/`

内置高质量示例数据，是产品"啊哈时刻"的关键组成部分，建议在 MVP 阶段就完成：

| 文件 | 内容 |
|------|------|
| `SwiftUILearning.json` | 一个 SwiftUI 学习 Collection，含多个 Page 和 Node 结构 |
| `ProjectPlanning.json` | 一个项目规划 Collection |
| `ReadingNotes.json` | 一个读书笔记 Collection |

---

### `Tests/` — 测试层 [INFRA]

| 子目录 | 覆盖范围 |
|--------|----------|
| `UnitTests/` | Domain 层 UseCase、NodeEditorEngine 命令逻辑、Repository |
| `IntegrationTests/` | 跨层流程测试（如：创建 Collection → 添加 Node → 持久化验证） |
| `UITests/` | 主路径 UI 自动化测试（Onboarding → 创建 → 编辑 → 退出重进） |

NodeEditor 的单元测试优先级最高：树构建、indent/outdent、折叠可见性计算必须有完整覆盖。

---

### `Docs/` — 工程文档 [INFRA]

| 文件 | 内容 |
|------|------|
| `Architecture.md` | 架构分层说明、模块依赖图 |
| `DataModel.md` | Collection / Page / Node / Block 字段定义、排序策略、BlockType 演进记录、迁移历史 |
| `Changelog.md` | 各版本变更记录 |

---

## 架构分层总图

```
┌──────────────────────────────────────────┐
│              App Layer                   │  入口、路由、依赖装配
├──────────────────────────────────────────┤
│           Features Layer                 │  功能模块（View + ViewModel + UseCase）
├──────────────────────────────────────────┤
│            Domain Layer                  │  业务实体、协议、纯逻辑（无框架依赖）
├──────────────────────────────────────────┤
│             Data Layer                   │  Repository、SwiftData、Sync、Export
├──────────────────────────────────────────┤
│  Shared / Platform / Infrastructure      │  组件库、多平台适配、工程设施
└──────────────────────────────────────────┘
```

依赖方向：App → Features → Domain ← Data  
Features 和 Data 均依赖 Domain，但 Features 不直接依赖 Data（通过 UseCase/Repository 协议解耦）。

---

## MVP 阶段最小必要目录

如果只关注 MVP，只需要以下目录：

```
Notte/
├── App/
├── Features/
│   ├── Onboarding/
│   ├── Collections/
│   ├── Pages/
│   ├── NodeEditor/
│   └── Settings/
├── Domain/
├── Data/
│   ├── Models/
│   ├── Repositories/
│   ├── Persistence/
│   └── Sync/              ← MVP 后半段接入
├── Shared/
├── Platform/
│   └── iPhone/
├── Infrastructure/
├── Resources/
│   └── SampleData/
└── Tests/
```

`POST` 标注的目录在 MVP 阶段可只创建空目录占位，不放任何实现文件。

---

## 开发阶段与目录对应关系

| 开发阶段 | 新增/激活的主要目录 |
|----------|-------------------|
| 阶段 1：定义冻结与工程底座 | `App/`、`Domain/Entities/`、`Data/Persistence/`、`Shared/Theme/`、`Infrastructure/` |
| 阶段 2：Collection 模块 | `Features/Collections/`、`Data/Repositories/CollectionRepository` |
| 阶段 3：Page 模块 | `Features/Pages/`、`Data/Repositories/PageRepository` |
| 阶段 4：Node Editor Core | `Features/NodeEditor/Engine/`、`Features/NodeEditor/Commands/`、`Features/NodeEditor/Services/` |
| 阶段 5：Node Editor UX | `Features/NodeEditor/` 内部完善 |
| 阶段 6：Onboarding & Settings | `Features/Onboarding/`、`Features/Settings/`、`Resources/SampleData/` |
| 阶段 7：iCloud Sync Beta | `Data/Sync/` |
| 阶段 8：QA & Release | `Tests/` 补全、`Docs/` 整理 |
| v0.2+：Search | `Features/Search/` |
| v0.3+：Templates & MapView | `Features/Templates/`、`Features/MapView/` |
| v0.4+：Export | `Features/Export/`、`Data/Export/` |
| v0.5+：Collaboration & AI | `Features/Collaboration/`、`Features/AI/`、`Data/Cloud/`、`Platform/iPad/`、`Platform/macOS/` |
