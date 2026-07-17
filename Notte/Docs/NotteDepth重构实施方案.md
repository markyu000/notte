# depth 去持久化重构实施方案

**状态** 全部决策项已拍定，可进入实现
**Version** v1.6（§4 补充定性说明：该节是终态清单而非执行顺序，删除 `Node.depth` 的时机以 §7 步骤 4 为准，§3.3 依赖的并存期不被 §4 的措辞抹掉；此前 v1.5 的 `subtreeHeight` 算法与 v1.4 的各项决策均不变）
**Tech Stack** SwiftUI + SwiftData + CloudKit
**关联文档** [Notte数据存储方案.md](./Notte数据存储方案.md) §2「depth 不进持久层」（设计原则已定案）、Notte数据模型定义.md

> 本文档是 §2 设计原则的**落地实施方案**：数据存储方案文档描述的是"应该长成什么样"，本文档描述"从当前代码现状到那个目标要改哪些文件、按什么顺序改、每一步怎么验证"。当前代码尚未实现 §2 的设计——`NodeModel`/`Node` 仍持久化 `depth` 字段，`buildTree` 仍直接拷贝而非重算。

---

## 目录

1. [现状](#1-现状)
2. [目标](#2-目标)
3. [关键设计决策](#3-关键设计决策)
4. [分层改动清单](#4-分层改动清单)
5. [SwiftData 迁移策略](#5-swiftdata-迁移策略)
6. [测试改动清单](#6-测试改动清单)
7. [实施顺序](#7-实施顺序)
8. [风险与验证点](#8-风险与验证点)

---

## 1. 现状

`depth` 目前在三层重复持久化 / 存在：

| 层 | 文件 | 说明 |
|---|---|---|
| SwiftData 持久层 | `Data/Models/NodeModel.swift:17` | `var depth: Int = 0`，真实存库字段 |
| Domain 层 | `Domain/Entities/Node.swift:15` | `var depth: Int`，NodeModel 的镜像 |
| 运行时树 | `Features/NodeEditor/Engine/EditorNode.swift:17` | `var depth: Int`，UI 渲染直接读这个 |

`NodeQueryService.buildTree`（`Features/NodeEditor/Services/NodeQueryService.swift:16-69`）已经存在，但第 42 行是**直接拷贝** `node.depth`，不是重算：

```swift
editorNodes[node.id] = EditorNode(
    ...
    depth: node.depth,   // ← 拷贝持久值，不是重算
    ...
)
```

`NodeMutationService.indent`（`Services/NodeMutationService.swift:193-230`）和 `outdent`（232-269）在改 `parentNodeID` 的同时，**额外对整棵子孙子树做批量 depth ± 1 的持久化写入**：

```swift
// indent 节选，223-228 行
for var desc in descendants {
    desc.depth += 1
    desc.updatedAt = Date()
    try await nodeRepository.update(desc)   // ← 子孙逐个写库
}
```

这是"手动维护 + 持久化写放大"的核心问题：一次 indent，子树多深就要多少次额外的库写入。

`NodeHierarchyPolicy.canAddChild(parentDepth:)` / `canIndent(subtreeMaxDepth:)`（`Shared/Utilities/NodeHierarchyPolicy.swift`）目前吃的都是现成的 `Int`，来自 `parentNode.depth` 或 `descendants.map(\.depth)`——这些值改造后不再存在，校验点要同步换血。

---

## 2. 目标

- 持久层（`Node` / `NodeModel`）**不存 depth**，只存 `parentNodeID` + `sortIndex`。
- `EditorNode.depth` 由 `buildTree` **每次全量重算**（DFS 下传 `parent.depth + 1`）。
- 结构变动（indent / outdent / 插入子节点）**只改持久层的 `parentNodeID` / `sortIndex`**，子孙节点一个字段都不碰。
- 不增量、不缓存、不手动维护 depth——`EditorNode` 树是一次性不可变快照，一变就整棵重建。

---

## 3. 关键设计决策

### 3.1 indent 深度校验：子树相对高度，不是节点自身深度

**问题**：如果校验只看被移动节点自己的深度（`depth(of: nodeID) + 1 <= maxDepth`），会漏判——indent 时整棵子树跟着下沉，真正可能顶到上限的是子树里最深的子孙，不是节点自己。

#### maxDepth 取值：沿用现有代码，不做改动

现有代码 `NodeHierarchyPolicy.swift:16-18`：

```swift
static let maxLevel = 5
static let maxDepth = maxLevel - 1   // = 4
```

`canAddChild(parentDepth:)` 是 `parentDepth < maxDepth`，`canIndent(subtreeMaxDepth:)` 是 `subtreeMaxDepth < maxDepth`——按此语义，depth **0、1、2、3、4 均合法**（5 级），depth 5 及以上被结构性禁止产生。本次重构**按现有代码语义原样保留**，`maxDepth` 取值、`NodeHierarchyPolicy`、`TypographyTokens.nodeTitleUI` 均不改动。

*已知但本次不处理的记录*：`Notte数据模型定义.md`「depth 语义」表（第 146-158 行）描述的是 depth 0-5 对应 h1-h6（6 级）、depth 6+ 继续缩进只是不再变样式；这与现有代码的 5 级封顶不一致。这个不一致在重构前就存在，不是本次改动引入的，也不在本次 depth 去持久化的范围内——按现有代码为准，数据模型文档如需更新是后续单独的事。

**反例**：节点 A 当前 depth = 2，其下挂子节点 B（depth 3）、孙节点 C（depth 4，已是当前规则下的最大合法深度）——即 `subtreeHeight(of: A) = 2`（C 相对 A 差 2 层）。A 前面有个同级兄弟 P（depth 同为 2）。indent 把 A 挂到 P 下面：`newDepth = depth(P) + 1 = 3`。

- 只看节点自己：`newDepth(3) <= maxDepth(4)` → 会**错误地放行**。
- 但子树跟着整体下沉，C 的新深度会变成 `newDepth + subtreeHeight = 3 + 2 = 5`，已经超出现有规则允许的最大深度 4——这个 indent 本该被挡住。
- 正确公式：`newDepth + height <= maxDepth` → `3 + 2 = 5 > 4` → 正确挡住。

这就是必须按子树高度校验、而不是只看节点自身深度的具体原因。

**方案**：新增两个纯函数，都从 `parentNodeID` 关系派生，不依赖任何持久化的绝对 depth：

```swift
// 单点查询：沿 parentNodeID 链向上走到根，返回跳数。O(链深)。
func depth(of nodeID: UUID, in nodes: [Node]) -> Int {
    let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
    var d = 0, cur = byID[nodeID]?.parentNodeID
    while let id = cur { d += 1; cur = byID[id]?.parentNodeID }
    return d
}

// 子树相对高度：从 nodeID 顺着树往下走到最深的叶子，边走边计数层级，取最大值。
// 与 buildTree 同一套思路（先按 parentNodeID 分组，再递归 DFS 往下），
// 只走一趟下行遍历，不需要对每个子孙再单独往上走一次。
// 建分组表 O(n) + 遍历子树 O(子树大小)，比"对每个子孙分别往上数"更省。
func subtreeHeight(of nodeID: UUID, in nodes: [Node]) -> Int {
    let childrenByParent = Dictionary(grouping: nodes, by: \.parentNodeID)
    func maxDepth(from id: UUID) -> Int {
        (childrenByParent[id] ?? []).map { 1 + maxDepth(from: $0.id) }.max() ?? 0
    }
    return maxDepth(from: nodeID)
}
```

现有代码里 `indent` 的深度校验（`NodeMutationService.swift:203-206`）其实已经是这个"顺树往下找、判断"的路数——`descendants(of:)` 本身就是从 `nodeID` 往下的 BFS，只是现在因为 `depth` 还持久化在每个节点上，走到子孙节点后可以直接 `.map(\.depth)` 白读现成值，不需要现场计数。重构后没有持久化 depth 可读，`subtreeHeight` 就是把"读现成值"换成"边往下走边数层级"，遍历路径（顺树往下找到最深处）本身没变。

`indent` 里的校验从"看节点自己"改成：

```swift
let newDepth = queryService.depth(of: newParent.id, in: nodes) + 1
let height = queryService.subtreeHeight(of: nodeID, in: nodes)
guard newDepth + height <= NodeHierarchyPolicy.maxDepth else { return }
```

`outdent` **不做深度上限校验**——深度只会减少，不可能超上限，维持原方案判断不变。

`NodeHierarchyPolicy.canIndent(subtreeMaxDepth:)` 签名不变，调用方传入 `newDepth + height` 这个等效"子树最深值"即可，策略层不用感知内部怎么算出来的。

### 3.2 SwiftData 迁移策略：确认选 (a) 本地数据可丢弃

删除 `@Model` 的一个非可选存储属性，不是"轻量迁移自动处理"能一句话带过的（cerebrum 里记录的"新增可空属性=轻量迁移"针对的是新增，不是删除）。已确认按 [§5](#5-swiftdata-迁移策略) (a) 处理：本地模拟器/真机上的数据可丢弃，直接删字段，不加 `SchemaV2`/`MigrationStage`，开发期验证方式是"删 app 重装"。

### 3.3 buildTree 改造前先跑一次等价性证明

不能凭"看起来逻辑对"就直接删掉持久层的 `depth` 字段。改造 `buildTree` 为重算之后（此时 `Node.depth` 还没删，新旧两套并存），加一条临时 parity 测试：遍历 `buildTree` 输出的每个 `EditorNode`，断言其重算出的 `depth` 与该节点对应 `Node.depth`（旧持久值）完全相等。跑绿才证明"重算逻辑与旧持久值等价"，才能放心进入删字段阶段。这条测试的断言依赖 `Node.depth` 存在，删字段时必须**连它一起删除**，不能留着变成编译报错清单里的意外项（见 [§7 步骤 4](#7-实施顺序)）。

---

## 4. 分层改动清单

> **本节是终态清单,不是执行顺序**——描述的是"全部改完之后每个文件长什么样",不代表这些改动可以一把梭同时做。特别注意:§4.1 删除 `Node.depth` 属于 [§7 步骤 4](#7-实施顺序),在此之前有一段**并存期**(§4.3 的 `buildTree` 已改为重算、但 `Node.depth` 仍保留),[§3.3](#33-buildtree-改造前先跑一次等价性证明) 的 parity 测试正是靠这段并存期才能拿"重算值"和"旧持久值"对比。执行时序一律以 [§7](#7-实施顺序) 为准。

### 4.1 Domain 层

`Domain/Entities/Node.swift` — 删除 `var depth: Int`（第 15 行）。保留 `parentNodeID`、`sortIndex` 不变。**时机：[§7 步骤 4](#7-实施顺序)**，不能和 §4.3 的 `buildTree` 改造同批做——步骤 1-3 的并存期需要它还在。

### 4.2 Data 层

`Data/Models/NodeModel.swift` — 删除 `depth` 存储属性（17 行）、初始化参数（28、38 行）、`toDomain()` 里的映射（53 行）。

`Data/Repositories/NodeRepository.swift` — `create`（40 行）、`update`（61 行）里的 `depth: node.depth` / `model.depth = node.depth` 删除。

### 4.3 Features 层

`Features/NodeEditor/Services/NodeQueryService.swift`：

- `buildTree` 的 `buildNode(_ id:)` 递归函数（58-62 行）改为携带 `depth` 参数，根节点传 0，每递归一层 `depth + 1`，赋给 `EditorNode.depth`。不再读 `node.depth`。
- 新增 `depth(of:in:)`、`subtreeHeight(of:in:)`（见 [§3.1](#31-indent-深度校验子树相对高度不是节点自身深度)）。

`Features/NodeEditor/Services/NodeMutationService.swift`：

- `insertTopLevel`（27 行）、`insertAfter`（69 行）、`insertChild`（110 行）里 `depth: ...` 这几个初始化参数删除（`Node` 初始化器不再有这个字段）。
- `insertChild` 的深度校验（99 行 `NodeHierarchyPolicy.canAddChild(parentDepth: parentNode.depth)`）改为 `NodeHierarchyPolicy.canAddChild(parentDepth: queryService.depth(of: nodeID, in: nodes))`。
- `indent`（193-230 行）：深度校验改用 [§3.1](#31-indent-深度校验子树相对高度不是节点自身深度) 的公式；删除 218 行 `updatedNode.depth = ...`；删除 223-228 行整段"批量更新子孙 depth"循环。改动后只 `update` 被移动节点自身的 `parentNodeID` + `sortIndex`，子孙节点**零写入**。
- `outdent`（232-269 行）：删除 256 行 `updatedNode.depth = ...`；删除 261-267 行整段批量子孙 depth 更新循环。同样只改被移动节点自身。

`Features/NodeEditor/Engine/EditorNode.swift` — 不改。`depth`、`subtreeMaxDepth` 结构不变，语义不变，只是现在保证"永远是 buildTree 现算的"。

`Shared/Utilities/NodeHierarchyPolicy.swift` — 不改。`canAddChild`/`canIndent` 签名保持不变，调用方负责传入正确算好的 `Int`。

`Features/Onboarding/Services/ExampleDataFactory.swift` — `persistNodes`（第 100 行）里 `depth: dto.depth` 传给 `Node` 初始化器的这一行删除。`SampleNodeDTO.depth` 字段（第 156 行）本身是 JSON fixture 的层级标注，不算持久层，可以保留不动，改动面最小。

### 4.4 消费方（不用改）

`NodeRowView.swift`、`PageEditorView.swift`、`TypographyTokens.swift`、`PageEditorViewModel.swift` 里读的都是 `EditorNode.depth`，不是 `Node.depth`，本次改动后依然可读，值只是"来源从拷贝变成现算"，无需改动。

---

## 5. SwiftData 迁移策略

现状核查：`Data/Persistence/MigrationPlan.swift` 只定义了 `SchemaV1`，`NotteMigrationPlan.stages` 是空数组——项目至今从未做过正式的 `MigrationStage` 迁移。

**已确认：(a) 本地数据可丢弃。** 直接删字段，不加 `SchemaV2`/`MigrationStage`；开发期验证方式是"删 app 重装"，不需要"带旧数据跑一次升级"这条路径。

### 5.1 CloudKit 时机：当前窗口是开着的，但未来要注意

CloudKit 生产 schema 字段只能加不能删——一旦 `depth` 被写进生产 CloudKit schema，就永久删不掉，只能留一个废弃字段活到项目终结。这本该是个硬约束，但核查现状后确认**当前不构成阻塞**：

- `Data/Persistence/PersistenceController.swift:43-49` 的 `cloudKitDatabase` 在 DEBUG 恒为 `.none`；Release 分支虽写的是 `effectiveICloudSyncEnabled ? .automatic : .none`，但**用户确认目前 `cloudKitDatabase` 实际恒为 `.none`，且从未打过真正的 Release 构建**——也就是说 `depth` 从未被推送到生产 CloudKit schema，删除零负担，可以直接物理删除，不需要"标记废弃"的降级方案。
- **面向未来的提醒**：`effectiveICloudSyncEnabled` 默认值是 `true`（`PersistenceController.swift:15`），意味着一旦真的打出 Release 构建且不主动关闭 iCloud 同步，`.automatic` 会立刻生效——不是绑定在某个"M7 milestone 开关"上才会触发的。所以这次 depth 删除**必须赶在项目第一次打 Release 构建（哪怕只是 TestFlight）之前完成**，越早做完这个清理，越不用担心以后被 CloudKit schema 锁死。

---

## 6. 测试改动清单

### 6.1 新增：parity 临时测试（第一步产出，第四步删除）

`NodeQueryServiceDepthParityTests`（新建，临时）：**在测试内部自洽构造一批 fixture `Node`**（不读取真实 SwiftData store / 不依赖模拟器上已有的本地数据），跑 `buildTree`，断言每个 `EditorNode.depth` == fixture 里同一节点手工指定的 `Node.depth`（旧持久值语义）。用于验证"重算逻辑与旧持久值等价"。

刻意强调"自洽构造"：如果这条测试读的是真实库里可能因历史 bug 已经跑偏的 `depth` 数据，跑绿或跑红都无法归因——分不清是"重算逻辑写错了"还是"库里数据本来就脏"。测试数据必须是测试自己造的、已知正确的 `parentNodeID` 结构。

此测试在 [§7 步骤 4](#7-实施顺序) 删除 `Node.depth` 时**必须一并删除**，不能留到编译报错阶段才处理。

### 6.2 直接操作 Domain `Node` 的测试 — 断言改法

涉及文件：`NodeMutationServiceIndentTests`、`NodeMutationServiceOutdentTests`、`NodeMutationServiceInsertAfterTests`、`NodeMutationServiceDeleteTests`、`NodeMutationServiceToggleCollapseTests`、`NodeMutationServiceMoveTests`、`NodePersistenceCoordinatorTests`、`LocalDataIntegrityTests`、`DeletePageUseCaseTests`。

- 各文件里的 `makeNode(depth:...)` 辅助函数删除 `depth` 参数。
- 原本 `XCTAssertEqual(updated?.depth, 1)` 这类断言，改成断言 `parentNodeID`：
  - indent 后：`updatedNode.parentNodeID == newParent.id`
  - outdent 后：`updatedNode.parentNodeID == parentNode.parentNodeID`

### 6.3 验证渲染深度的测试 — 改为"只给结构，depth 由 buildTree 现算后断言"

涉及文件：`NodeQueryServiceVisibleNodesTests`、`NodeQueryServiceTests`、`PageEditorViewModelLoadTests`、`ExampleDataFactoryTests`。

这些测试本来就该测"给定 parentNodeID 结构，`buildTree` 算出来的 depth 对不对"——保留 `depth` 断言，但输入侧不再手工传 `depth:`（Domain `Node` 没这个字段了），只传 `parentNodeID`，depth 完全由 `buildTree` 算出后再断言。这是一次测试质量的顺带提升，不是纯粹的迁移负担。

### 6.4 端到端测试更名

`NodeEditorEndToEndTests.swift:62-72`（测试名"indent 后节点 parentNodeID 和 depth 持久化正确"）——"depth 持久化"这个说法以后不成立，改为验证"parentNodeID 持久化正确 + 重新 fetch 后 buildTree 出来的 depth 正确"，测试名同步改。

---

## 7. 实施顺序

1. `NodeQueryService` 新增 `depth(of:in:)` + `subtreeHeight(of:in:)`；`buildTree` 改为递归重算 depth。新增并跑绿 [§6.1](#61-新增parity-临时测试第一步产出第四步删除) 的 parity 测试（自洽构造 fixture，不读真实 store）。此时 `Node.depth` 仍在，新旧两套并存可对比。
2. 前置准备：确认 [§5](#5-swiftdata-迁移策略) 已选 (a) 直接删字段——不需要额外操作，只是提醒验证方式是"删 app 重装"，不用准备迁移 stage。
3. `NodeMutationService.indent` 改用 [§3.1](#31-indent-深度校验子树相对高度不是节点自身深度) 的校验公式（`maxDepth` 沿用现有代码值 4，不改 `NodeHierarchyPolicy`）；`indent`/`outdent` 删除批量子孙 depth 写入循环，只留 `parentNodeID` + `sortIndex` 更新；`insertChild` 深度校验改用 `depth(of:in:)`。
4. 删除 `Node` / `NodeModel` / `NodeRepository` 里的 `depth`。**先删掉步骤 1 的 parity 临时测试**，再让编译报错驱动改完 `insertTopLevel` / `insertAfter` / `insertChild` / `ExampleDataFactory` 等调用点。
5. 按 [§6.2](#62-直接操作-domain-node-的测试--断言改法)、[§6.3](#63-验证渲染深度的测试--改为只给结构depth-由-buildtree-现算后断言)、[§6.4](#64-端到端测试更名) 批量修其余测试。
6. 全量跑测试；删 app 重装模拟器验证多级 indent/outdent，重点覆盖 [§3.1](#31-indent-深度校验子树相对高度不是节点自身深度) 反例那种"子树整体逼近上限"的边界场景（A depth 2 / B depth 3 / C depth 4，indent A 到同级兄弟下应被挡住）。

---

## 8. 风险与验证点

- **迁移风险**：即使选了 [§5](#5-swiftdata-迁移策略) (a)（直接删字段、不加迁移 stage），删除已上线的非可选存储属性后仍建议在模拟器上删 app 重装实测一遍，确认没有残留崩溃或异常，不能只凭经验判断"删了就没事"。
- **CloudKit 时机**：[§5.1](#51-cloudkit-时机当前窗口是开着的但未来要注意) 已确认当前无负担，但要赶在项目第一次打 Release 构建之前完成，不能无限期拖延。
- **深度校验反例覆盖**：[§3.1](#31-indent-深度校验子树相对高度不是节点自身深度) 描述的"子树比节点自身深"场景必须有专门测试用例覆盖（`NodeMutationServiceIndentTests` 里补一条子树多层嵌套、indent 后触顶的用例，用 `maxDepth=4` 构造边界），不能只靠通用 indent 测试碰运气覆盖到。
- **性能**：`buildTree` 单 Page 几十到几百节点，O(n)。`depth(of:)` 单次调用是"建 `[UUID: Node]` 字典 O(n) + 沿链上溯 O(链深)"；`subtreeHeight(of:)` 改成顺树往下一趟遍历（`Dictionary(grouping:by:)` 建 `parentID → children` 分组表 O(n) + 递归 DFS 往下 O(子树大小)），不再是"对每个子孙分别往上数"那个更贵的版本。`indent` 一次校验里这两个函数各自独立建一次表，等于两次 O(n)。单 Page 几十到几百节点量级下远小于 SwiftUI diff 成本，无需额外优化。
