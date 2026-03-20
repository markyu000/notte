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
| Node | 大纲条目，既是结构单元，也是内容载体 |
| Block | Node 下的内容块，开发者层级概念，用户不直接感知 |

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
| `title` | 大纲条目名称，永远不为空 |
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
| 5 | 五级缩进 | h6 |
| 6+ | 继续缩进 | 维持 h6 样式，只增加缩进距离 |

### MVP 边界

- Node 无 `type` 字段，类型语义由 depth 与其下 Block 决定
- Node 可以没有任何 Block（纯大纲条目）
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
| Node 无 `type` 字段 | Node 是纯大纲条目，类型语义交给 Block 表达 |
| Block 对用户不可见 | Block 是开发者概念，用户感知的是 Node 下的内容区域 |
| 扁平存储 | 更适合 SwiftData，查询稳定，同步更容易 |
| `sortIndex` 浮点数 | 支持任意位置插入，避免整体重排 |
| MVP 只保留 `text` Block | bullet / image / code / quote 均为 Post-MVP |
| 删除父节点级联删除子节点 | 行为直观，实现简单，无需复杂"提升子节点"逻辑 |
