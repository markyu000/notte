# Notte MVP 功能范围文档

**Milestone** M0 · Definition  
**Version** v1.0  
**Tech Stack** SwiftUI + SwiftData + CloudKit  
**Target** iPhone（MVP 主平台）  
**Core Model** Collection → Page → Node → Block

---

## 目录

1. [文档目的](#1-文档目的)
2. [MVP 定位](#2-mvp-定位)
3. [核心主路径](#3-核心主路径)
4. [In-Scope 功能列表](#4-in-scope-功能列表)
5. [Out-of-Scope 列表](#5-out-of-scope-列表)
6. [数据模型边界](#6-数据模型边界)
7. [工程原则](#7-工程原则)
8. [M0 验收标准](#8-m0-验收标准)
9. [范围变更规则](#9-范围变更规则)

---

## 1. 文档目的

本文档是 M0 阶段核心交付物之一。**在第一行代码落地之前**，明确 MVP 的功能边界，使开发决策有据可依。

- **In-Scope** 定义"做什么"——MVP 允许开发的功能范围
- **Out-of-Scope** 定义"不做什么"——所有超出此列表的想法一律进入 Backlog，标记 `scope/post-mvp`
- 边界一旦锁定，新需求必须经过显式的范围变更评估，不可静默扩展

> 本文档不是产品愿景，不是设计规范，只服务于 MVP 阶段的范围共识。

---

## 2. MVP 定位

Notte MVP 不是功能大全。它只需要证明一件事：

> **用户能够创建 Collection、在其中创建 Page、在 Page 中通过 Node 大纲结构组织文字内容，并在重启后保留所有数据。**

MVP 成立的标志是**主路径流畅、数据可靠、基础同步可用**，而非功能全覆盖。

---

## 3. 核心主路径

所有功能取舍以此主路径为唯一判断依据：

```
打开 App
  → 进入 Collection 列表
  → 创建 Collection，设置标题
  → 进入 Collection → 创建 Page
  → 进入 Page → 创建第一个 Node
  → 编辑 Node 标题与 Block 文字内容
  → 调整 Node 层级与顺序
  → 退出 App，重启后数据完整保留        ← Local-first 闭环
  → （可选）iCloud 跨设备同步
```

> **判断原则：任何不在以上链路上的能力，都不进入 MVP。**  
> `Collection → Page → Node → Block` 这条线之外的一切，均为 Post-MVP。

---

## 4. In-Scope 功能列表

以下功能明确进入 MVP。所有 GitHub Issue 标记 `scope/mvp`。

---

### 4.1 Collection 模块

| 功能 | 说明 |
|---|---|
| 创建 Collection | 输入标题创建，支持设置 emoji 图标与颜色标识 |
| 编辑 Collection | 修改标题、图标、颜色 |
| 删除 Collection | 删除后级联清理所有 Page、Node、Block |
| Collection 列表展示 | 卡片式列表，显示标题、图标、Page 数量 |
| 固定（Pin） | 支持将常用 Collection 固定在顶部 |
| 手动排序 | 长按拖动调整 Collection 显示顺序，基于 `sortIndex` |
| 空状态 | 列表为空时显示引导提示 |

---

### 4.2 Page 模块

| 功能 | 说明 |
|---|---|
| 创建 Page | 在 Collection 内创建 Page，输入标题 |
| 编辑 Page 标题 | 修改 Page 名称 |
| 删除 Page | 级联清理所有 Node 与 Block |
| Page 列表展示 | 行式列表，显示标题与最后更新时间 |
| 手动排序 | 长按拖动调整 Page 顺序，基于 `sortIndex` |
| 归档 Page | 将 Page 标记为归档，不在主列表显示 |
| 空状态 | Page 列表为空时显示引导提示 |

---

### 4.3 Node 编辑器

Node 是 Notte 的核心单元。每个 Node 有标题（大纲条目）和内容区（Block 列表）两部分，`depth` 决定缩进层级与标题渲染级别（h1–h6）。

| 功能 | 说明 |
|---|---|
| 创建 Node | 在 Page 中新建大纲条目，必有标题 |
| 编辑 Node 标题 | 标题即大纲显示文字，depth 0–5 对应 h1–h6，超过 5 维持 h6 样式 |
| 删除 Node | 删除 Node 及其所有子 Node 与 Block |
| Node 嵌套（缩进） | Tab 增加缩进，Shift+Tab 减少缩进，深度不做人为上限 |
| Node 排序 | 拖动调整 Node 在同级中的排列顺序 |
| 折叠 / 展开 | 折叠收起子树，展开恢复，折叠状态持久化 |
| Block 文字内容编辑 | 在 Node 内容区编辑 `text` 类型 Block，支持多段 |
| Block 增删 | 创建与删除 text Block，`sortIndex` 自动维护 |
| 回车插入新 Node | 在 Node 标题行回车，自动在下方插入同级新 Node 并聚焦 |
| 退格删除空 Node | 在空 Node 标题行退格，删除该 Node 并聚焦到上一 Node 末尾 |
| 焦点管理 | 键盘操作时焦点自动跳转到正确 Node / Block |
| 自动保存 | 编辑内容实时持久化，无需手动保存按钮 |
| 大纲视图（Outline View） | MVP 唯一视图模式，树状大纲展示 |

---

### 4.4 持久化（Local-first）

| 功能 | 说明 |
|---|---|
| SwiftData 本地存储 | 所有数据写入本地 SwiftData 容器，完全离线可用 |
| 重启数据保留 | App 强退重启后数据完整，无丢失 |
| 级联删除 | 删除父对象时，所有子对象一并清除 |
| `sortIndex` 排序策略 | 初始间隔 1000，插入取中间值，后台定期 normalize |
| Schema 迁移基础设施 | `MigrationPlan` 就位，支持未来模型变更 |

---

### 4.5 iCloud 基础同步

同步是 MVP 后半段能力（M7），本地主路径稳定后才接入。

| 功能 | 说明 |
|---|---|
| CloudKit 基础同步 | Collection / Page / Node / Block 核心数据跨设备同步 |
| 离线编辑 | 无网络时本地编辑正常，上线后自动同步 |
| 同步失败容错 | 同步失败不破坏本地数据，有基础错误提示 |
| iCloud 不可用时降级 | 未登录 iCloud 时，纯本地模式正常运行，功能不受影响 |

---

### 4.6 Onboarding & 设置

| 功能 | 说明 |
|---|---|
| 首次启动引导 | 简短引导页，解释核心模型，不超过 3 步 |
| 示例数据导入 | 一键导入示例 Collection，帮助用户理解结构 |
| 基础设置页 | App 版本信息、反馈入口、调试菜单（`#if DEBUG` only） |
| 深色模式支持 | 完整 Light / Dark 模式适配，所有页面覆盖 |
| Dynamic Type 适配 | 最大字号下布局不破损 |
| iPhone SE 兼容 | 375pt 小屏下主路径无截断、无遮挡 |

---

## 5. Out-of-Scope 列表

以下功能**明确不进入 MVP**。所有相关 Issue 标记 `scope/post-mvp`，进入 Backlog 等待评估。

| 功能类别 | 具体说明 |
|---|---|
| **AI 功能** | 摘要生成、语义搜索、内容建议、AI 写作助手 |
| **协作与多人编辑** | 实时协作、评论、多人权限管理 |
| **模板市场与分享** | 模板上传、下载、社区分享、Collection 模板 |
| **Map View（思维导图）** | 将 Node 树渲染为可视化思维导图视图 |
| **非 text Block 类型** | `bullet`、`image`、`code`、`quote` 等 Block 类型 |
| **复杂导出** | PDF 导出、图片思维导图、Markdown 批量导出 |
| **Web 版 / Notte Cloud** | 跨平台 Web 访问、自建云服务后端 |
| **跨 Page Node 引用** | Node 在不同 Page 之间的引用、复用、嵌入 |
| **子 Collection（嵌套）** | Collection 内嵌套子 Collection 层级结构 |
| **iPad 双栏布局** | iPad 专属 Split View 双栏交互设计 |
| **macOS 多窗口** | macOS 原生多窗口策略与适配 |
| **全局搜索** | 跨 Collection 全文搜索、Node 级语义搜索 |
| **Share Sheet** | 系统级 Share Extension 快速收藏外部内容 |
| **快捷指令集成** | Shortcuts.app 自动化流程集成 |
| **Apple Pencil** | 手写输入与 Pencil 专属交互 |
| **Spotlight 集成** | 系统搜索索引 Collection / Page 内容 |
| **附件管理** | 图片、PDF、音视频等附件存储与预览 |
| **商业化功能** | 订阅、内购、高级 iCloud 同步层、Pro 功能 |

---

## 6. 数据模型边界

MVP 只存在以下四个数据对象，不引入更多高阶抽象。

### Collection

```swift
struct Collection {
    var id: UUID
    var title: String
    var iconName: String?      // emoji 图标
    var colorToken: String?    // 颜色标识
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isPinned: Bool
}
```

### Page

```swift
struct Page {
    var id: UUID
    var collectionID: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Double
    var isArchived: Bool
}
```

### Node

```swift
struct Node {
    var id: UUID
    var pageID: UUID
    var parentNodeID: UUID?    // nil 表示根节点
    var title: String          // 大纲条目标题，永远存在
    var depth: Int             // 0–5 对应 h1–h6；超过 5 维持 h6 样式
    var sortIndex: Double
    var isCollapsed: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

### Block

```swift
struct Block {
    var id: UUID
    var nodeID: UUID
    var type: BlockType        // MVP 只有 .text
    var content: String
    var sortIndex: Double
    var createdAt: Date
    var updatedAt: Date
}

enum BlockType: String, Codable {
    case text   // MVP
    // POST: bullet, image, code, quote
}
```

### 架构约束

- `Domain/Entities/`：纯 Swift struct，无框架依赖
- `Data/Models/`：SwiftData `@Model` 类，与 Domain 实体保持字段映射
- Repository 负责两层之间的转换，View / ViewModel 只接触 Domain 实体
- 所有 `@Model` 使用**扁平结构**，不做嵌套持久化

---

## 7. 工程原则

| 原则 | 说明 |
|---|---|
| **结构优先** | 所有设计围绕 `Collection → Page → Node Tree → Block List` |
| **Local-first** | 本地闭环先成立，iCloud 是后续增强，不是 MVP 前提 |
| **简单模型** | 不过度抽象，不引入多余高阶对象 |
| **单一主路径** | 主路径流畅优先于功能覆盖广度 |
| **iPhone 先行** | 所有核心逻辑先在 iPhone 完成，iPad / macOS 后续适配 |
| **晚接入同步** | 本地模型与编辑器稳定后再接入 CloudKit |

---

## 8. M0 验收标准

M0 阶段自身的验收不涉及代码，只需确认**文档与工程配置**全部就绪。

| # | 验收条件 | 交付物 |
|---|---|---|
| 1 | MVP In-Scope / Out-of-Scope 文档已确认（本文档） | `NotteMVP功能范围文档.md` |
| 2 | 核心用户旅程文档已完成（主路径一张图） | `核心用户旅程.md` |
| 3 | 数据模型字段定义 v0 已确认 | `NotteMVP工程设计文档.md` |
| 4 | 命名规范文档已确认（类名、文件、变量） | `命名规范.md` |
| 5 | GitHub Issue 模板已就位 | `.github/ISSUE_TEMPLATE/` |
| 6 | GitHub PR 模板已就位 | `.github/PULL_REQUEST_TEMPLATE.md` |
| 7 | 分支策略文档已确认 | `Notte_Git规范.md` |
| 8 | GitHub Project 看板已配置（列、Labels、Milestones） | GitHub Project |

---

## 9. 范围变更规则

MVP 边界由本文档锁定。所有后续需求变更必须遵循以下流程，**不允许静默扩展**：

1. **提出**：创建 GitHub Issue，默认标记 `scope/post-mvp`，进入 Backlog
2. **评估**：判断是否影响主路径稳定性或拉长 MVP 周期
3. **决策**：
   - 纳入 MVP → 更新本文档 + 重新评估当前 Milestone 工作量
   - 保留 Backlog → 维持 `scope/post-mvp` 标记，待 MVP 发布后评估
4. **执行**：未经步骤 3 明确决策的功能，一律不开发

---

> **一条主线，始终不变：**
>
> ```
> Collection → Page → Node → Block
> ```
>
> 任何不在这条链路上的能力，都不进入 MVP。
