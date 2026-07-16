# Notte 数据存储方案

**Milestone** M8 · UI Polish 期间确立
**Version** v1.0
**Tech Stack** SwiftUI + SwiftData + CloudKit
**Target** iPhone（MVP 主平台）
**关联文档** Notte数据模型定义.md、Notte_M4代码参考文档.md、Notte_M7代码参考文档.md

---

## 目录

1. [核心原则](#1-核心原则)
2. [depth 不进持久层](#2-depth-不进持久层)
3. [变动的数据流](#3-变动的数据流)
4. [两类变动的落盘节奏](#4-两类变动的落盘节奏)
5. [退出时的持久化保障](#5-退出时的持久化保障)
6. [不可逆操作的确认前置](#6-不可逆操作的确认前置)
7. [草稿快照（Post-MVP 加固）](#7-草稿快照post-mvp-加固)
8. [运行时序：用户正在输入时存储模块的动作](#8-运行时序用户正在输入时存储模块的动作)
9. [术语](#9-术语)
10. [设计原则说明](#10-设计原则说明)

---

## 1. 核心原则

**内存优先，持久层异步。**

内存里的 `[Node]` 扁平数组是**运行时唯一真相**。所有变动先落在它上面、立刻刷新 UI，SwiftData 只是异步的持久化目标，永远不挡在交互的关键路径上。

```
内存 [Node]（真相）
   ├── buildTree ──▶ EditorNode 树（派生快照，含 depth）──▶ UI
   └── 异步 flush ──▶ SwiftData ──sync──▶ CloudKit
```

三者关系明确：

| 层 | 角色 |
|---|---|
| 内存 `[Node]` | 运行时 source of truth，所有变动先落于此 |
| `EditorNode` 树 | 内存数组的派生快照，每次 `buildTree` 当场重算，含 depth |
| SwiftData `@Model` | 异步持久化目标，**不作为运行时真相**，不边改边等它回读 |
| CloudKit | SwiftData 背后自行异步同步，存储模块不等待、不管理 |

> 关键边界：不要把 SwiftData 的 `@Model` 对象直接当运行时真相、边改边等它回读——那会把 UI 绑死在持久层上。三层引擎（Engine / MutationService / QueryService）本就是为隔开这层而存在，保持这个边界。

---

## 2. depth 不进持久层

depth 本质是相对的：`node.depth == parent.depth + 1`，即"从根到该节点的父链长度"。存绝对值是把派生数据冗余持久化，会导致每次 indent/outdent 都要遍历整棵子树逐个改写 depth 并写库。

### 决策

- **`Node` / `NodeModel` 不含 depth 字段**，持久层只存 `parentNodeID + sortIndex`
- **`EditorNode.depth` 由 `buildTree` 每次全量重算**（DFS 下传 `parent.depth + 1`），不持久化、不缓存、不手动维护
- 单点查询 depth（如 `maxDepthExceeded` 校验）走 `QueryService` 沿父链上溯的辅助方法

### buildTree 递归下传 depth

`parent.depth + 1` 这个递推归属于 `buildTree` 的 DFS，不是 `Node` 上的计算属性（纯 struct 拿不到全体节点，做计算属性会退化成沿父链上溯，O(链深) 且整树渲染时大量重复计算）。

```swift
func buildTree(from nodes: [Node]) -> [EditorNode] {
    let childrenByParent = Dictionary(grouping: nodes, by: \.parentNodeID)

    func build(_ node: Node, depth: Int) -> EditorNode {
        let children = (childrenByParent[node.id] ?? [])
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { build($0, depth: depth + 1) }   // ← parent.depth + 1 在这里
        return EditorNode(id: node.id, depth: depth, title: node.title,
                          isCollapsed: node.isCollapsed, children: children,
                          blocks: /* ... */)
    }

    return (childrenByParent[nil] ?? [])
        .sorted { $0.sortIndex < $1.sortIndex }
        .map { build($0, depth: 0) }
}
```

### 单点查询辅助方法

```swift
func depth(of nodeID: UUID, in nodes: [Node]) -> Int {
    let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
    var d = 0, cur = byID[nodeID]?.parentNodeID
    while let id = cur { d += 1; cur = byID[id]?.parentNodeID }
    return d
}
```

`indent` 校验时，目标深度 = 新父在内存树里现成的 `depth + 1`，O(1)。

### 为什么不选 materialized path（路径串）

把 depth 存成路径字符串（如 `"a.c.f"`）**解决不了批量更新痛点**：移动子树时子树所有节点的 path 前缀照样全部重写，甚至比 Int 更重。path 的唯一优势"一次前缀查询捞整棵子树"在 Notte 用不上——Notte 是 `fetchAll(in: pageID)` 全量取出、内存 `buildTree`，不靠数据库做子树查询。所以 path 缺点全继承、优点用不上，不采用。

### 放弃持久化 depth 的取舍

- 不能用 `#Predicate` 直接按 depth 过滤/排序 → 当前全量取再内存建树，无此需求，YAGNI
- 单看一个 Node 记录不知道是 h 几 → 渲染永远走 `EditorNode`，拿到即带 depth，无代价
- `maxDepthExceeded` 校验 → 基于内存树算目标深度 = 新父 depth + 1，O(1)

### 对 M7 / CloudKit 的加分

绝对 depth 的一次 indent 产生 N 条 Node 记录变更上传，多设备并发冲突面大；改成只动一个 `parentNodeID`，变更集最小，CloudKit 冲突合并更友好。

---

## 3. 变动的数据流

任何结构 / 文本变动，顺序都是**先内存、再 UI、后持久层**，绝不"先写库再刷新"。

```
1. 改内存 [Node]（结构变动只动被移动节点的 parentNodeID / sortIndex）
2. buildTree 重建 → 立刻刷新 UI（depth 当场算）
3. 标记 dirty → 按落盘节奏异步 flush 到 SwiftData
```

### 为什么不能"先写库再刷新"

Repository / MutationService 是 `async`，写 SwiftData 要 await。若"先 await 写库成功 → 再刷 UI"，用户每次输入/缩进都要等磁盘写完 UI 才动，轻则黏滞、重则掉帧；SwiftData + CloudKit 下写库还可能触发同步合并，更不该让 UI 等它。

### 重建即更新，不做增量

把 `EditorNode` 树当成**一次性不可变快照**：结构一变，不是"更新旧树里某些节点的 depth"，而是用新数据建新树、丢旧树。depth 永远最新，不存在"过期需要更新"的状态。

`buildTree` 是 O(n)（单 Page 几十到几百节点，微秒级，远小于 SwiftUI diff 成本）。不做增量 patch——增量会重新引入"持久层改 parentNodeID + 运行时树局部改 depth"两条必须时刻一致的修改路径，等于把刚砍掉的多点同步复杂度从数据库层搬到内存层，一分没省还多一处能写错。只有当某 Page 大到 `buildTree` 真的掉帧时才优化，且届时应做渲染虚拟化而非增量维护 depth。

---

## 4. 两类变动的落盘节奏

| 变动类型 | 频率 | 落盘策略 |
|---|---|---|
| **文本编辑**（Block 内容） | 高频 | 内存优先 + **debounce 500ms–1s** 后 flush |
| **结构 / 层级变动**（indent / outdent / 移动 / 删除） | 低频 | 内存优先 + **立即异步 flush**（不 debounce） |

### 文本编辑用 debounce

连续输入期间不断取消并重启计时器，一次都不写；用户停手超过阈值（视为一阵输入告一段落）才合并写一次，把几十次磁盘写压成一次。

```swift
private var saveTask: Task<Void, Never>?

func contentDidChange() {
    saveTask?.cancel()
    saveTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await flush()          // 异步，不阻塞 UI
    }
}
```

debounce 阈值取较短（500ms–1s），把"未落盘 dirty"窗口压到最小，降低对退出强制 flush 的依赖。

### 结构变动立即异步 flush

结构变动频率远低于打字，一次 indent 就一条记录，没必要攒。变动后先刷 UI、紧接着 fire 一个异步写（仍不阻塞 UI）。这样结构层几乎永远是已落盘的，进后台时要补的只剩正在输入的文本。

---

## 5. 退出时的持久化保障

**核心：把"进后台"当成硬提交点，进后台时 dirty 必须清零。不依赖任何"临终"回调。**

### 三种"退出"分开看

| 事件 | 系统信号 | 处理 |
|---|---|---|
| 切后台（Home / 上滑到桌面） | `scenePhase` → `.background` | **flush 主战场**，同步写完 dirty |
| 从后台被系统杀掉 | 收不到任何回调 | 靠"进后台已存完"兜底 |
| 上滑强杀（app switcher 划掉） | 基本无可靠回调 | 靠"进后台已存完"兜底（强杀前通常先经过进后台） |

结论：不能等"要被杀了"才存，必须在**进后台那一刻**就已存完。

### 进后台 flush 实现要点

```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .background || newPhase == .inactive {
        editorViewModel.flushNow()   // 同步、绕过 debounce、把 dirty 全写完再返回
    }
}
```

- **`.inactive` 也要 flush**，不只 `.background`——来电、控制中心下拉、多任务切换都会先过 `.inactive`，提前存更安全
- flush 要在后台时间预算内跑完；数据量大时用 `beginBackgroundTask(withName:)` 申请一小段后台时间包住写入，写完 `endBackgroundTask`
- `flushNow()` 是幂等的强制版，绕过 debounce 计时器——不是"重置计时器"，是"立刻把所有 dirty 写完再返回"

---

## 6. 不可逆操作的确认前置

删除这类不可逆操作，在**改内存之前**先弹级联影响确认对话框（M8 的"该 Collection 含 3 个 Page"），用户确认后再走"改内存 → 刷 UI → 异步删库"。确认发生在动手前，不是让持久化卡在关键路径上，两回事。

---

## 7. 草稿快照（Post-MVP 加固）

崩溃、断电这类连"进后台"都没有的极端情况，任何内存优先方案都会丢最后一点未落盘数据。MVP 阶段"进后台强制 flush + 短 debounce"已覆盖 99% 真实场景，本节列为 **post-MVP 加固，MVP 不做**。

### 必须用 throttle，不是 debounce

草稿要防的恰恰是"用户连续不停打字时崩溃"——此时 debounce 计时器一直被重置，永远不落盘，跟 SwiftData flush 有同样缺口。**throttle（节流）保证"连续期间也保底落盘"**：不管多频繁，最多每 X 秒落一次，且连续期间保证落。

```
debounce：打字打字打字...停手 → 才写（连续期间 0 次）
throttle：打字打字打字打字打字 → 每 15s 强制落一次（连续期间也在落）
```

### 参数与规则

| 项 | 定值 |
|---|---|
| 频率 | **throttle 10–15 秒一次，且仅在有 dirty 时写** |
| 写法 | **原子写**：写临时文件 → `rename` 覆盖正式草稿文件，避免写到一半崩溃损坏草稿本身 |
| 文件 | 每个活跃 Page 一个草稿文件，覆盖写，不累积历史 |
| 清除 | **正式 flush 成功后清草稿**（或标记已提交），否则下次启动会拿已正式落盘的旧草稿去"恢复"，造成困惑 |
| 进后台 | **不写草稿**——进后台已强制 flush 到 SwiftData（更正式），此时直接清草稿 |
| 启动检测 | 发现"未标记已提交"的草稿 → 说明上次异常退出 → 提示用户恢复 |

10–15 秒足够：崩溃/断电罕见，草稿只在"两次 SwiftData flush 之间恰好崩溃"的极窄交集里有价值，最坏丢 10–15 秒输入对个人笔记可接受；单 Page 序列化几十到几百 KB，15 秒一次磁盘和电量都无感。

### 分工

- **SwiftData（debounce + 结构立即 + 进后台强制）= 正式存储**，负责 99% 正常场景
- **草稿快照（throttle 10–15s）= 崩溃保险**，只兜"连正常退出都没发生"的 1%

两者目的不同、节奏相反（debounce vs throttle），不用同一套机制。

---

## 8. 运行时序：用户正在输入时存储模块的动作

场景：用户坐在一个 Block 里连续打字。

| 时刻 | 内存 / UI | SwiftData（debounce） | 草稿快照（throttle，post-MVP） |
|---|---|---|---|
| 敲第一个字 | 字符进内存 Block content，UI 立即渲染（零延迟，不碰存储） | 置 dirty，起 500ms 计时器 | — |
| 连续打字 | 每字更新内存 + 刷 UI | 计时器不断取消重启，**一次不写** | 每 10–15s 保底原子写一次 |
| 停手 >500ms | — | 计时器到点，**异步 flush 一次**，清 dirty | 标记已提交 / 清除 |
| 又开始打 | 立即更新 | 重新置 dirty + 重启计时器 | 继续自身节奏 |
| 切后台 | — | **同步 flushNow 立即写完**，必要时 beginBackgroundTask 包住 | 清除 |

两条节奏同时跑但相反：**SwiftData 在"憋着不写"，草稿在"定期保底写"**——这正是二者分工的意义。用户全程感觉不到任何存储动作，数据在多个节奏保护下逐层落盘。

---

## 9. 术语

**debounce（防抖）** — "等用户停手再做"。事件在短时间内反复触发时，每次触发都重置计时器，只有最后一次触发后的一段安静期结束才真正执行。用于高频文本输入，把海量小写入合并成少量。天生缺口：用户"打完立刻退出"时计时器还没到点就被打断——由进后台强制 flush 补。

**throttle（节流）** — "不管多频繁，最多每 X 秒一次，且连续期间保证落"。与 debounce 相反，连续触发期间也会周期性执行。用于草稿快照，保证连续输入时也定期落盘。

**flush** — 把内存中标记为 dirty 的数据写入持久层的动作。`flushNow()` 为绕过 debounce 的同步强制版，用于进后台等硬提交点。

---

## 10. 设计原则说明

| 原则 | 决策 |
|---|---|
| 内存是运行时唯一真相 | 变动先落内存，UI 即时响应，持久层异步跟随 |
| depth 不持久化 | 只存 `parentNodeID + sortIndex`，depth 由 `buildTree` 全量重算 |
| 重建即更新，不做增量 | `EditorNode` 树是一次性快照；结构变动 = 只改持久层父指针 + 重建树 |
| 先内存再 UI 后持久层 | 绝不"先写库再刷新"，交互不挂在持久化关键路径上 |
| 文本 debounce，结构立即 | 高频文本合并写；低频结构一条一记录，直接异步写 |
| 进后台强制 flush 兜底 | 硬提交点在"进后台"，不依赖被杀 / 强杀的临终回调 |
| 草稿用 throttle 非 debounce | 崩溃保险要连续期间保底落盘，列为 post-MVP 加固 |
| 不可逆操作确认前置 | 删除确认发生在改内存之前，不阻塞持久化 |

---

**一句话总纲：** 内存是真相，UI 即时响应，持久层异步跟随；文本 debounce、结构立即写；进后台强制 flush 兜底；depth 全程只在运行时算。
