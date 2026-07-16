# Notte 数据模型定义 v0

**Milestone** M0 · Definition  
**Issue** [M0] Define Collection / Page / Node / Block data model v0  
**Version** v0.1  
**Tech Stack** SwiftUI + SwiftData + CloudKit  
**Target** iPhone（MVP 主平台）  
**Core Model** Collection → Page → Node → Block

---

## 目录

1. [模型层级总览](#1-模型层级总览)
2. [Collection](#2-collection)
3. [Page](#3-page)
4. [Node](#4-node)
5. [Block](#5-block)
6. [存储方案](#6-存储方案)
7. [运行时模型](#7-运行时模型)
8. [设计原则说明](#8-设计原则说明)
9. [模板与组件复用机制](#9-模板与组件复用机制)

---

## 1. 模型层级总览

```
Collection
  └─ Page
       └─ Node（扁平存储，运行时构建树）
            └─ Block
```

四个实体的职责边界：

| 实体 | 职责 |
|---|---|
| Collection | 一级组织单位，承载若干 Page |
| Page | 二级容器，Node Tree 的宿主 |
| Node | **组件框架**：标题（可选）+ 内容区。既是大纲结构单元（缩进 / 层级 / 折叠），也是内容的组织框架；内容本身由其内容区的 Block 承载 |
| Block | Node 内容区里的内容块，开发者层级概念，用户不直接感知 |

> **Node = 组件框架。** Node 由「标题（可选）」和「内容区」两部分构成，是一个可被复用、可被养成模板的最小组件单位。用户感知到的是「一个可折叠、可缩进、可写内容的条目」；「Block」「子树」「组件」这些词只存在于代码与本文档中，永不进入 UI。

---

## 2. Collection

### 字段定义

```text
id:          UUID
title:       String
iconName:    String?
colorToken:  String?
createdAt:   Date
updatedAt:   Date
sortIndex:   Double
isPinned:    Bool
```

### 字段说明

| 字段 | 说明 |
|---|---|
| `id` | 全局唯一标识，UUID |
| `title` | 用户设置的名称，不可为空 |
| `iconName` | SF Symbol 名称，可选 |
| `colorToken` | 颜色 token 字符串，可选 |
| `createdAt` | 创建时间 |
| `updatedAt` | 最后修改时间 |
| `sortIndex` | 排序用浮点数，初始间隔 1000，插入取相邻中间值 |
| `isPinned` | 是否固定到列表顶部 |

### MVP 边界

- 不加描述块、标签、权限、统计等衍生字段
- 不支持嵌套 Collection（sub-Collection 为 Post-MVP）

---

## 3. Page

### 字段定义

```text
id:           UUID
collectionID: UUID
title:        String
createdAt:    Date
updatedAt:    Date
sortIndex:    Double
isArchived:   Bool
```

### 字段说明

| 字段 | 说明 |
|---|---|
| `id` | 全局唯一标识 |
| `collectionID` | 所属 Collection 的 ID，外键关联 |
| `title` | 页面标题，不可为空 |
| `createdAt` | 创建时间 |
| `updatedAt` | 最后修改时间 |
| `sortIndex` | 在 Collection 内的排序值 |
| `isArchived` | 是否归档，归档后从主列表隐藏 |

### MVP 边界

- 不加封面、模板继承、复杂属性面板
- 删除行为：直接删除，级联清除该 Page 下所有 Node 与 Block

---

## 4. Node

### 字段定义

```text
id:           UUID
pageID:       UUID
parentNodeID: UUID?
title:        String
depth:        Int
sortIndex:    Double
isCollapsed:  Bool
createdAt:    Date
updatedAt:    Date
```

### 字段说明

| 字段 | 说明 |
|---|---|
| `id` | 全局唯一标识 |
| `pageID` | 所属 Page 的 ID |
| `parentNodeID` | 父节点 ID，为 `nil` 时表示根节点 |
| `title` | 组件标题，**可为空**。空标题的 Node 作为「隐形容器」存在（只承担结构 / 分组职责，不在大纲中显示标题文字） |
| `depth` | 缩进层级，同时决定标题渲染级别（见下） |
| `sortIndex` | 在同级兄弟节点中的排序值 |
| `isCollapsed` | 是否折叠子节点 |
| `createdAt` | 创建时间 |
| `updatedAt` | 最后修改时间 |

### depth 语义

`depth` 同时承担两个职责，不设单独的 `level` 字段：

| depth | 缩进层级 | 标题渲染 |
|---|---|---|
| 0 | 根级 | h1 |
| 1 | 一级缩进 | h2 |
| 2 | 二级缩进 | h3 |
| 3 | 三级缩进 | h4 |
| 4 | 四级缩进 | h5 |

### MVP 边界

- Node 无 `type` 字段，类型语义由 depth 与其下 Block 决定
- Node 是**组件框架**：标题（可为空）+ 内容区；内容区可以为空（纯结构条目），也可以承载 Block
- `title` 可为空：空标题 Node 作为隐形容器使用
- 可被复用 / 模板化的最小单位是 **Node 子树**（Node + 内容 + 全部子 Node），而非孤立单个 Node（见第 9 节）
- 删除父节点时，同时删除全部子节点（不做"提升子节点"策略）

---

## 5. Block

### 字段定义

```text
id:        UUID
nodeID:    UUID
type:      BlockType
content:   String
sortIndex: Double
createdAt: Date
updatedAt: Date
```

### 字段说明

| 字段 | 说明 |
|---|---|
| `id` | 全局唯一标识 |
| `nodeID` | 所属 Node 的 ID |
| `type` | Block 类型，见 BlockType |
| `content` | 内容字符串：text 存正文，image 存路径，code 存代码字符串 |
| `sortIndex` | 在同一 Node 下的排序值 |
| `createdAt` | 创建时间 |
| `updatedAt` | 最后修改时间 |

### BlockType

**MVP 阶段只保留：**

```swift
enum BlockType: String, Codable {
    case text   // 正文段落
}
```

**Post-MVP 按需扩展：**

```swift
// case bullet  // 列表项（圆点样式）
// case image   // content 存图片路径或 asset ID
// case code    // content 存代码字符串，language 元数据可 JSON 存入 content
// case quote   // 引用段落样式
```

### Node 与 Block 职责边界

| 操作 | 由谁负责 |
|---|---|
| 折叠 / 展开 | Node |
| 缩进 / 反缩进 | Node |
| 拖动 / 排序 | Node |
| 文字内容编辑 | Block |
| 图片 / 代码 / 引用 | Block（Post-MVP） |

Block 类型不影响 Node 的结构操作逻辑，所有 Node 的折叠、拖动、缩进行为完全一致。

---

## 6. 存储方案

### 持久化结构

采用**扁平存储**，不做嵌套持久化：

```
Node：parentNodeID + sortIndex + depth  → 扁平存储，运行时构建树
Block：nodeID + sortIndex               → 按 Node 关联，扁平存储
```

### sortIndex 策略

- 初始值每项间隔 **1000**
- 插入时取相邻两项的**中间值**
- 定期在后台做 normalize，防止精度耗尽

### SwiftData 层

存储模型（`Data/Models/`）与 Domain 实体（`Domain/Entities/`）分离：

```
Domain/Entities/
  Collection.swift   ← 纯 Swift struct，无框架依赖
  Page.swift
  Node.swift
  Block.swift
  BlockType.swift

Data/Models/
  CollectionModel.swift   ← @Model class，SwiftData 持久化
  PageModel.swift
  NodeModel.swift
  BlockModel.swift
```

Repository 负责在 `@Model` 类与 Domain 实体之间做映射转换。

---

## 7. 运行时模型

持久化是扁平的，编辑器内部使用树形运行时模型：

### EditorNode

```text
EditorNode
  id:          UUID
  parentID:    UUID?
  depth:       Int
  title:       String
  isCollapsed: Bool
  visible:     Bool
  children:    [EditorNode]
  blocks:      [EditorBlock]   ← 该 Node 下的内容块，按 sortIndex 排列
```

### EditorBlock

```text
EditorBlock
  id:      UUID
  type:    BlockType
  content: String
```

**两层模型的职责：**

| 层 | 结构 | 职责 |
|---|---|---|
| 存储模型 | 扁平 | 持久化、同步 |
| 运行时模型 | 树形 | 编辑器渲染、交互 |

---

## 8. 设计原则说明

| 原则 | 决策 |
|---|---|
| `depth` 统一缩进与标题级别 | 不设单独 `level` 字段，避免两字段语义割裂 |
| Node 无 `type` 字段 | Node 是组件框架，类型语义交给 depth 与其下 Block 表达 |
| Node = 组件框架（标题可选 + 内容区） | 让「大纲条目」「可复用组件」「模板单位」三者统一为同一抽象，避免多套并行结构 |
| `title` 可为空 | 支持隐形容器；标题不是内容的必要条件，降低记录阻力 |
| 组件 / 模板的单位是 Node 子树 | 单个 Node 无法独立表达结构；子树才是可复用的完整语义单元 |
| Block 对用户不可见 | Block 是开发者概念，用户感知的是 Node 下的内容区域 |
| 扁平存储 | 更适合 SwiftData，查询稳定，同步更容易 |
| `sortIndex` 浮点数 | 支持任意位置插入，避免整体重排 |
| MVP 只保留 `text` Block | bullet / image / code / quote 均为 Post-MVP |
| 删除父节点级联删除子节点 | 行为直观，实现简单，无需复杂"提升子节点"逻辑 |
| 插入 Node 模板用相对 depth | 保留模板内部层级关系，整体以插入点为基准平移，防止标题级别错乱（见第 9 节） |

---

## 9. 模板与组件复用机制

### 9.1 核心抽象：组件 = Node 子树

Notte 的复用与模板能力，全部建立在一个统一抽象之上：

> **可被复用 / 可被模板化的单位是「Node 子树」（一个 Node + 它的内容区 Block + 它的全部子 Node），而不是孤立的单个 Node。**

这一条把三件此前分开描述的能力收敛为同一个机制：

| 能力 | 本质 |
|---|---|
| Node 跨 Page 复用 | 取出一段子树，插入到另一处 |
| Node 模板 | 把一段子树存下来，以后重复插入 |
| Page 模板 | 把一整页的 node 树存下来，用于新建 Page |

它们**不是三套系统，而是同一套「存子树 / 取子树」机制在不同范围上的表现**。数据结构、序列化逻辑、UI 交互都可以共用。

### 9.2 两层模板：同机制，两范围

模板分为两层，底层机制相同（存 / 插一段 Node 子树），区别只在**范围**与**落点**：

| 层级 | 存储内容 | 落点 | 对用户的动作 |
|---|---|---|---|
| **Page 模板** | 一整个 Page 的 node 树（从 depth 0 起） | 新建一个 Page | 「从模板新建页面」 |
| **Node 模板** | 一段 Node 子树（单 Node + 内容 + 子 Node） | 插入到当前 Page 的光标 / 选中位置 | 「插入模板」 |

> **Collection 模板**（Post-MVP）是更外层的扩展：本质是「一组 Page 模板的打包」，用于一次性搭建整个专题空间。不属于 MVP 的两层核心机制。

### 9.3 关键实现规则：插入 Node 模板用「相对 depth」

插入 Node 模板时，**必须以插入点的 depth 为基准，对模板内部所有 Node 的 depth 做整体平移，而非沿用模板存储时的绝对 depth**。

- 模板**内部**各 Node 之间的相对层级关系（谁是谁的子节点）保持不变；
- 模板**整体**的根 depth = 插入点 depth（或插入点 depth + 1，取决于「插为兄弟」还是「插为子节点」的交互约定）；
- 否则：一个在 depth 0（h1）存下的模板，插到 depth 2 的节点下面时，会把本该是 h4 的内容渲染成 h1，标题级别错乱。

**Page 模板不涉及此问题**：它是新开一整页、从 depth 0 重建，绝对 depth 与存储时一致。

### 9.4 与"简单默认，强大可选"的关系

模板是 Notte 让「自定义能力」既强大又不制造复杂度的**主入口**。分层策略：

| 档位 | 机制 | MVP 态度 |
|---|---|---|
| 模板档 | 用户把搭好的子树存成模板，以后复用 | ✅ 主推。零新概念，用户只是「把上次那个存下来再用」 |
| 轻 schema 档 | Node 带预设类型（任务 / 代码 / 折叠等） | ⏸ 缓行。每加一种类型 +1 分概念重量 |
| 可编程档 | 用户写逻辑 / 配置 | ❌ 不做。这正是 Obsidian 复杂度的来源 |

「非常强大」不来自让用户去配置，而来自**预置高质量模板** + 后期服务端 AI 生成自定义功能（以 clean data API 为前提）。自定义能力藏在模板背后，用户觉得简单；摊在配置面前，就变成 Obsidian。
