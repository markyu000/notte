# Notte M4 代码参考文档

> 本文档包含 M4（Node Editor Core）阶段所有 issue 的文件路径、代码内容与解释。  
> M4 目标：Node 编辑核心闭环——增删缩进移动折叠全部成立，Block 内容可编辑，重启数据不丢。

---

## 分支

```
feature/m4-node-editor-core
```

## 目录

1. [M4-01 NodeRepositoryProtocol 升级](#m4-01-noderepositoryprotocol-升级)
2. [M4-02 BlockRepositoryProtocol 升级](#m4-02-blockrepositoryprotocol-升级)
3. [M4-03 NodeRepository 完整实现](#m4-03-noderepository-完整实现)
4. [M4-04 BlockRepository 完整实现](#m4-04-blockrepository-完整实现)
5. [M4-05 EditorNode 与 EditorBlock 运行时模型](#m4-05-editornode-与-editorblock-运行时模型)
6. [M4-06 NodeCommand 枚举](#m4-06-nodecommand-枚举)
7. [M4-07 BlockCommand 枚举](#m4-07-blockcommand-枚举)
8. [M4-08 NodeQueryService.buildTree 与 visibleNodes](#m4-08-nodequeryservicebuildtree-与-visiblenodes)
9. [M4-09 NodeQueryService.previousSibling](#m4-09-nodequeryserviceprevioussibling)
10. [M4-10 NodeQueryService.parent](#m4-10-nodequeryserviceparent)
11. [M4-11 NodeQueryService.descendants](#m4-11-nodequeryservicedescendants)
12. [M4-12 NodeMutationService.insertAfter 与 insertChild](#m4-12-nodemutationserviceinsertafter-与-insertchild)
13. [M4-13 NodeMutationService.delete](#m4-13-nodemutationservicedelete)
14. [M4-14 NodeMutationService.moveUp 与 moveDown](#m4-14-nodemutationservicemoveup-与-movedown)
15. [M4-15 NodeMutationService.indent 与 outdent](#m4-15-nodemutationserviceindent-与-outdent)
16. [M4-16 NodeMutationService.toggleCollapse 与 updateTitle](#m4-16-nodemutationservicetogglecollapse-与-updatetitle)
17. [M4-17 BlockEditingService（addBlock / deleteBlock / updateContent）](#m4-17-blockeditingserviceaddblock--deleteblock--updatecontent)
18. [M4-17b BlockEditingService.reorderBlock](#m4-17b-blockeditingservicereorderblock)
19. [M4-18 NodeEditorEngine](#m4-18-nodeeditorengine)
20. [M4-19 NodePersistenceCoordinator](#m4-19-nodepersistencecoordinator)
21. [M4-20 PageEditorViewModel](#m4-20-pageeditorviewmodel)
22. [M4-21 PageEditorView](#m4-21-pageeditorview)
23. [M4-22 NodeRowView](#m4-22-noderowview)
24. [M4-23 NodeContentEditor（UITextView 包装）](#m4-23-nodecontenteditoruitextview-包装)
25. [M4-24 NodeIndentationGuide](#m4-24-nodeindentationguide)
26. [M4-25 NodeCollapseControl](#m4-25-nodecollapsecontrol)
27. [M4-26 NodeTypeIndicator](#m4-26-nodetypeindicator)
28. [M4-27 DependencyContainer 更新](#m4-27-dependencycontainer-更新)
29. [M4-28 DeletePageUseCase Block 级联补全](#m4-28-deletepageusecase-block-级联补全)
30. [M4-29 AddNodeButton](#m4-29-addnodebutton)
31. [M4-30 键盘 Return → insertAfter 行为](#m4-30-键盘-return--insertafter-行为)
32. [M4-31 键盘 Backspace 空节点行为](#m4-31-键盘-backspace-空节点行为)
33. [M4-32 键盘 Tab → indent 行为](#m4-32-键盘-tab--indent-行为)
34. [M4-33 键盘 Shift+Tab → outdent 行为](#m4-33-键盘-shifttab--outdent-行为)
35. [M4-34 RootView 更新（接入 PageEditorView）](#m4-34-rootview-更新接入-pageeditorview)
36. [M4-35～50 单元测试与集成测试](#m4-3450-单元测试与集成测试)

---

## M4-01 NodeRepositoryProtocol 升级

**文件：** `Domain/Protocols/NodeRepositoryProtocol.swift`（在 M1 骨架基础上更新）

```swift
import Foundation

protocol NodeRepositoryProtocol {
    func fetchAll(in pageID: UUID) async throws -> [Node]
    func fetch(by id: UUID) async throws -> Node?
    func create(_ node: Node) async throws
    func update(_ node: Node) async throws
    func delete(by id: UUID) async throws
    func deleteAll(in pageID: UUID) async throws
}
```

**Git commit message：**

```
feat: upgrade NodeRepositoryProtocol to async throws
```

**解释：**

- M1 骨架阶段的 `NodeRepositoryProtocol` 方法签名为同步 `throws`。M4 开始真正实现 Node 模块，将协议升级为 `async throws`，与 M2 的 `CollectionRepositoryProtocol`、M3 的 `PageRepositoryProtocol` 升级方式完全对称。
- `deleteAll(in pageID:)` 在 M1 即已预留，M3 的 `DeletePageUseCase` 已调用，M4 提供完整实现后级联删除自动生效。
- `BlockRepositoryProtocol` 在同一 PR 内一并升级，见 M4-02。

---

## M4-02 BlockRepositoryProtocol 升级

**分支：** `feature/m4-repository-protocols`  
**文件：** `Domain/Protocols/BlockRepositoryProtocol.swift`（在 M1 骨架基础上更新）

```swift
import Foundation

protocol BlockRepositoryProtocol {
    func fetchAll(in nodeID: UUID) async throws -> [Block]
    func fetch(by id: UUID) async throws -> Block?
    func create(_ block: Block) async throws
    func update(_ block: Block) async throws
    func delete(by id: UUID) async throws
    func deleteAll(in nodeID: UUID) async throws
}
```

**Git commit message：**

```
feat: upgrade BlockRepositoryProtocol to async throws
```

**解释：**

- 与 `NodeRepositoryProtocol` 同 PR 升级，保持四个 Repository Protocol 签名风格统一。
- `deleteAll(in nodeID:)` 在删除 Node 时触发，由 `NodeMutationService.delete` 内部调用，UseCase 层不直接感知 Block 的级联清理。
- 协议升级后，`BlockRepository` 的骨架实现（M1 已建）方法签名需同步改为 `async throws`，详见 M4-04。

---

## M4-03 NodeRepository 完整实现

**分支：** `feature/m4-node-repository`  
**文件：** `Data/Repositories/NodeRepository.swift`

```swift
import Foundation
import SwiftData

class NodeRepository: NodeRepositoryProtocol {

    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in pageID: UUID) async throws -> [Node] {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.pageID == pageID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func fetch(by id: UUID) async throws -> Node? {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first.map { $0.toDomain() }
    }

    func create(_ node: Node) async throws {
        let model = NodeModel(
            id: node.id,
            pageID: node.pageID,
            parentNodeID: node.parentNodeID,
            title: node.title,
            depth: node.depth,
            sortIndex: node.sortIndex,
            isCollapsed: node.isCollapsed,
            createdAt: node.createdAt,
            updatedAt: node.updatedAt
        )
        context.insert(model)
        try context.save()
    }

    func update(_ node: Node) async throws {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.id == node.id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.pageID = node.pageID
        model.parentNodeID = node.parentNodeID
        model.title = node.title
        model.depth = node.depth
        model.sortIndex = node.sortIndex
        model.isCollapsed = node.isCollapsed
        model.updatedAt = node.updatedAt
        try context.save()
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }

    func deleteAll(in pageID: UUID) async throws {
        let descriptor = FetchDescriptor<NodeModel>(
            predicate: #Predicate { $0.pageID == pageID }
        )
        let models = try context.fetch(descriptor)
        for model in models {
            context.delete(model)
        }
        try context.save()
    }
}
```

**Git commit message：**

```
feat: implement NodeRepository full CRUD
```

**解释：**

- 与 M2 `CollectionRepository`、M3 `PageRepository` 的实现结构完全对称：`FetchDescriptor` 查询 + `toDomain()` 转换 + `context.save()` 持久化。
- `fetchAll(in pageID:)` 在 `FetchDescriptor` 内加 `sortBy: [SortDescriptor(\.sortIndex)]`，从数据库层就保证按 sortIndex 顺序返回，不需要在 Service 层再排序。
- `deleteAll(in pageID:)` 逐个删除而不是批量删除，确保 SwiftData 能正确触发关联对象的生命周期钩子，兼容性更稳定。
- `update` 时不更新 `createdAt`，时间戳语义正确：创建时间不可变，只有 `updatedAt` 随变更刷新。

---

## M4-04 BlockRepository 完整实现

**分支：** `feature/m4-block-repository`  
**文件：** `Data/Repositories/BlockRepository.swift`

```swift
import Foundation
import SwiftData

class BlockRepository: BlockRepositoryProtocol {

    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(in nodeID: UUID) async throws -> [Block] {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.nodeID == nodeID },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func fetch(by id: UUID) async throws -> Block? {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first.map { $0.toDomain() }
    }

    func create(_ block: Block) async throws {
        let model = BlockModel(
            id: block.id,
            nodeID: block.nodeID,
            type: block.type.rawValue,
            content: block.content,
            sortIndex: block.sortIndex,
            createdAt: block.createdAt,
            updatedAt: block.updatedAt
        )
        context.insert(model)
        try context.save()
    }

    func update(_ block: Block) async throws {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.id == block.id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        model.nodeID = block.nodeID
        model.type = block.type.rawValue
        model.content = block.content
        model.sortIndex = block.sortIndex
        model.updatedAt = block.updatedAt
        try context.save()
    }

    func delete(by id: UUID) async throws {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(model)
        try context.save()
    }

    func deleteAll(in nodeID: UUID) async throws {
        let descriptor = FetchDescriptor<BlockModel>(
            predicate: #Predicate { $0.nodeID == nodeID }
        )
        let models = try context.fetch(descriptor)
        for model in models {
            context.delete(model)
        }
        try context.save()
    }
}
```

**Git commit message：**

```
feat: implement BlockRepository full CRUD
```

**解释：**

- `type` 在 `BlockModel` 里以 `String` 存储，`create` 时通过 `block.type.rawValue` 转换，与 M1 中 `BlockModel` 的设计保持一致。
- `deleteAll(in nodeID:)` 供 `NodeMutationService.delete` 调用，确保删除 Node 时关联 Block 被彻底清理，避免孤儿数据。
- MVP 阶段 Block 类型只有 `text`，但 `type` 字段完整保存，POST 阶段扩展类型时不需要做数据迁移。

---

## M4-05 EditorNode 与 EditorBlock 运行时模型

**分支：** `feature/m4-editor-runtime-models`  
**文件：** `Features/NodeEditor/Engine/EditorNode.swift`

```swift
import Foundation

/// Node 编辑器的运行时模型。
/// 存储模型（NodeModel/Node）是扁平的，EditorNode 是树形的，
/// 由 NodeQueryService.buildTree 从扁平列表构建。
struct EditorNode: Identifiable {
    let id: UUID
    var parentID: UUID?
    var title: String
    var depth: Int
    var sortIndex: Double
    var isCollapsed: Bool
    var isVisible: Bool
    var children: [EditorNode]
    var blocks: [EditorBlock]

    init(
        id: UUID,
        parentID: UUID? = nil,
        title: String,
        depth: Int,
        sortIndex: Double,
        isCollapsed: Bool = false,
        isVisible: Bool = true,
        children: [EditorNode] = [],
        blocks: [EditorBlock] = []
    ) {
        self.id = id
        self.parentID = parentID
        self.title = title
        self.depth = depth
        self.sortIndex = sortIndex
        self.isCollapsed = isCollapsed
        self.isVisible = isVisible
        self.children = children
        self.blocks = blocks
    }
}
```

**文件：** `Features/NodeEditor/Engine/EditorBlock.swift`

```swift
import Foundation

/// Block 的运行时模型，随所属 EditorNode 一起携带。
/// MVP 阶段 type 只有 .text，但结构已为 POST 类型预留。
struct EditorBlock: Identifiable {
    let id: UUID
    var type: BlockType
    var content: String
    var sortIndex: Double

    init(
        id: UUID,
        type: BlockType = .text,
        content: String = "",
        sortIndex: Double
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.sortIndex = sortIndex
    }
}
```

**Git commit message：**

```
feat: define EditorNode and EditorBlock runtime models
```

**解释：**

- `EditorNode` 和 `EditorBlock` 是编辑器的**运行时内存模型**，不持久化。持久化由 `Node` / `Block` domain entity 通过 Repository 负责。
- `children: [EditorNode]` 让树形结构在内存中可递归遍历，折叠可见性计算、缩进深度渲染都依赖这个结构。
- `isVisible` 控制该节点是否在列表中显示（折叠时子节点 `isVisible = false`）。这个字段由 `NodeQueryService.visibleNodes` 计算，不由用户直接设置。
- `blocks` 在 `NodeQueryService.buildTree` 阶段一并注入，保证 `NodeRowView` 渲染时能直接读取内容，不需要再额外查询。

---

## M4-06 NodeCommand 枚举

**分支：** `feature/m4-commands`  
**文件：** `Features/NodeEditor/Commands/NodeCommand.swift`

```swift
import Foundation

/// Node 结构层的操作命令。
/// 所有影响 Node 树结构的操作都通过此枚举统一表达，
/// 由 NodeEditorEngine.dispatch 路由到 NodeMutationService。
enum NodeCommand {
    /// 在指定节点后插入一个新的同级节点
    case insertAfter(nodeID: UUID)
    /// 在指定节点内部插入一个子节点（成为其最后一个子节点）
    case insertChild(nodeID: UUID)
    /// 删除指定节点及其全部子孙节点和关联 Block
    case delete(nodeID: UUID)
    /// 将节点与前一个同级节点互换位置
    case moveUp(nodeID: UUID)
    /// 将节点与后一个同级节点互换位置
    case moveDown(nodeID: UUID)
    /// 缩进：成为前一个同级节点的最后一个子节点
    case indent(nodeID: UUID)
    /// 反缩进：提升到父节点的同级，排在父节点之后
    case outdent(nodeID: UUID)
    /// 切换折叠/展开状态
    case toggleCollapse(nodeID: UUID)
    /// 更新节点标题
    case updateTitle(nodeID: UUID, title: String)
}
```

**Git commit message：**

```
feat: define NodeCommand enum
```

**解释：**

- 将所有 Node 结构操作收敛到一个枚举，是"命令模式"的体现。上层（ViewModel 或键盘响应）只需 `engine.dispatch(.indent(nodeID: id))` 即可触发操作，不需要直接调用各 Service 方法。
- 枚举关联值全部用 `nodeID: UUID` 标记参数名，清晰表达"对哪个 Node 做什么"。
- `updateTitle` 额外携带 `title: String`，因为标题本身就是参数，不同于其他操作只需要节点 id。
- Block 内容操作由独立的 `BlockCommand` 枚举负责，职责分离，见 M4-07。

---

## M4-07 BlockCommand 枚举

**分支：** `feature/m4-commands`  
**文件：** `Features/NodeEditor/Commands/BlockCommand.swift`

```swift
import Foundation

/// Block 内容层的操作命令。
/// 所有影响 Block 内容的操作都通过此枚举统一表达，
/// 由 NodeEditorEngine.dispatch 路由到 BlockEditingService。
enum BlockCommand {
    /// 在指定节点下新增一个指定类型的 Block
    case addBlock(nodeID: UUID, type: BlockType)
    /// 删除指定 Block
    case deleteBlock(blockID: UUID)
    /// 更新 Block 的文本内容
    case updateContent(blockID: UUID, content: String)
    /// 调整 Block 的排序位置
    case reorderBlock(blockID: UUID, newSortIndex: Double)
}
```

**Git commit message：**

```
feat: define BlockCommand enum
```

**解释：**

- 与 `NodeCommand` 分开定义，强调"Node 结构"与"Block 内容"是两个独立的操作维度。Node 操作不会修改 Block 内容，Block 操作不会影响 Node 树结构。
- `addBlock(nodeID:type:)` 明确了 Block 归属的 Node，创建时 `sortIndex` 由 `BlockEditingService` 内部计算。
- MVP 阶段 `addBlock` 传入的 `type` 通常固定为 `.text`，枚举中仍保留参数是为了 POST 阶段扩展类型时接口不变。

---

## M4-08 NodeQueryService.buildTree 与 visibleNodes

**分支：** `feature/m4-node-query-service`  
**文件：** `Features/NodeEditor/Services/NodeQueryService.swift`（新建，后续 M4-09～11 在同文件追加）

```swift
import Foundation

/// 负责 Node 树的只读查询：构建树、展平可见列表、查找父子与兄弟关系。
/// 所有方法均为纯函数，输入 Node 数组，输出查询结果，无副作用。
struct NodeQueryService {

    // MARK: - 树构建

    /// 将扁平 Node 列表 + Block 列表构建为树形 EditorNode 列表（只含根节点）
    func buildTree(nodes: [Node], blocks: [Block]) -> [EditorNode] {
        // 1. 将 Block 按 nodeID 分组
        var blocksByNodeID: [UUID: [Block]] = [:]
        for block in blocks {
            blocksByNodeID[block.nodeID, default: []].append(block)
        }

        // 2. 将每个 Node 转为 EditorNode（children 先为空）
        var editorNodes: [UUID: EditorNode] = [:]
        for node in nodes.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            let nodeBlocks = (blocksByNodeID[node.id] ?? [])
                .sorted { $0.sortIndex < $1.sortIndex }
                .map { EditorBlock(id: $0.id, type: $0.type, content: $0.content, sortIndex: $0.sortIndex) }
            editorNodes[node.id] = EditorNode(
                id: node.id,
                parentID: node.parentNodeID,
                title: node.title,
                depth: node.depth,
                sortIndex: node.sortIndex,
                isCollapsed: node.isCollapsed,
                blocks: nodeBlocks
            )
        }

        // 3. 建立父子关系
        var rootNodes: [EditorNode] = []
        for node in nodes.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            if let parentID = node.parentNodeID {
                editorNodes[parentID]?.children.append(editorNodes[node.id]!)
            } else {
                rootNodes.append(editorNodes[node.id]!)
            }
        }

        return rootNodes
    }

    /// 将树形结构展平为按视觉顺序排列的 EditorNode 列表（深度优先，前序遍历）
    /// 已折叠节点的子树不出现在结果中
    func visibleNodes(from roots: [EditorNode]) -> [EditorNode] {
        var result: [EditorNode] = []
        for root in roots {
            flatten(node: root, into: &result)
        }
        return result
    }

    private func flatten(node: EditorNode, into result: inout [EditorNode]) {
        var visible = node
        visible.isVisible = true
        result.append(visible)
        if !node.isCollapsed {
            for child in node.children.sorted(by: { $0.sortIndex < $1.sortIndex }) {
                flatten(node: child, into: &result)
            }
        }
    }
}
```

**Git commit message：**

```
feat: implement NodeQueryService buildTree and visibleNodes
```

**解释：**

- `buildTree` 分三步：先按 nodeID 分组 Block，再把 Node 映射为 EditorNode，最后建立 children 父子关联。必须先排序再遍历，否则 children 顺序依赖于内存布局。
- `visibleNodes` 用深度优先前序遍历展平树。折叠节点（`isCollapsed == true`）的子树不进入结果，这是折叠功能的核心实现。
- 两个方法均为纯函数，输入相同则输出相同，方便单元测试。

---

## M4-09 NodeQueryService.previousSibling

**分支：** `feature/m4-node-query-service`  
**文件：** `Features/NodeEditor/Services/NodeQueryService.swift`（在 M4-08 基础上追加方法）

```swift
extension NodeQueryService {
    /// 找到目标节点在同级中的前一个兄弟节点（sortIndex 最大且小于自身的同级节点）
    func previousSibling(of nodeID: UUID, in nodes: [Node]) -> Node? {
        guard let node = nodes.first(where: { $0.id == nodeID }) else { return nil }
        return nodes
            .filter { $0.parentNodeID == node.parentNodeID && $0.sortIndex < node.sortIndex }
            .sorted { $0.sortIndex < $1.sortIndex }
            .last
    }
}
```

**Git commit message：**

```
feat: add NodeQueryService.previousSibling
```

**解释：**

- 过滤条件：同级（`parentNodeID` 相同）且 `sortIndex` 小于目标节点，排序后取最后一个即为紧邻的前一个兄弟。
- `previousSibling` 是 `indent` 操作的基础：缩进时需要找到"要成为父节点"的那个节点，即当前节点的前一个同级节点。
- 返回 `nil` 时表示当前节点已在同级最前，`indent` 操作此时为 noop。

---

## M4-10 NodeQueryService.parent

**分支：** `feature/m4-node-query-service`  
**文件：** `Features/NodeEditor/Services/NodeQueryService.swift`（继续追加）

```swift
extension NodeQueryService {
    /// 找到目标节点的父节点
    func parent(of nodeID: UUID, in nodes: [Node]) -> Node? {
        guard let node = nodes.first(where: { $0.id == nodeID }),
              let parentID = node.parentNodeID else {
            return nil
        }
        return nodes.first { $0.id == parentID }
    }
}
```

**Git commit message：**

```
feat: add NodeQueryService.parent
```

**解释：**

- `parent` 是 `outdent` 操作的基础：反缩进时需要知道当前节点的父节点，才能计算"提升到父节点同级"后的新 `parentNodeID` 和 `sortIndex`。
- 根节点（`parentNodeID == nil`）返回 `nil`，`outdent` 遇到 `nil` 时为 noop，不会越界。

---

## M4-11 NodeQueryService.descendants

**分支：** `feature/m4-node-query-service`  
**文件：** `Features/NodeEditor/Services/NodeQueryService.swift`（继续追加）

```swift
extension NodeQueryService {
    /// 找到目标节点的全部子孙节点（不含自身），BFS 广度优先
    func descendants(of nodeID: UUID, in nodes: [Node]) -> [Node] {
        var result: [Node] = []
        var queue: [UUID] = [nodeID]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let directChildren = nodes.filter { $0.parentNodeID == current }
            result.append(contentsOf: directChildren)
            queue.append(contentsOf: directChildren.map(\.id))
        }
        return result
    }

    /// 找到目标节点的所有直接子节点，按 sortIndex 排序
    func children(of nodeID: UUID, in nodes: [Node]) -> [Node] {
        nodes.filter { $0.parentNodeID == nodeID }
             .sorted { $0.sortIndex < $1.sortIndex }
    }

    /// 找到目标节点在同级中的后一个兄弟节点
    func nextSibling(of nodeID: UUID, in nodes: [Node]) -> Node? {
        guard let node = nodes.first(where: { $0.id == nodeID }) else { return nil }
        return nodes
            .filter { $0.parentNodeID == node.parentNodeID && $0.sortIndex > node.sortIndex }
            .sorted { $0.sortIndex < $1.sortIndex }
            .first
    }
}
```

**Git commit message：**

```
feat: add NodeQueryService.descendants, children, nextSibling
```

**解释：**

- `descendants` 用 BFS 找全部后代（不含自身），用于 `delete` 和 `indent/outdent` 时批量更新 depth。从 `nodeID` 自身的直接子节点开始入队，不把自身放入结果。
- `children` 和 `nextSibling` 同批提交，它们是 `insertAfter`、`insertChild`、`indent` 等操作的辅助查询，与 `descendants` 同属关系查询层，合在一个 commit 最合理。

---

## M4-12 NodeMutationService.insertAfter 与 insertChild

**分支：** `feature/m4-node-mutation-service`  
**文件：** `Features/NodeEditor/Services/NodeMutationService.swift`（新建）

```swift
import Foundation

/// 负责执行 Node 结构变更操作。
/// 每个方法都会直接读写 Repository，调用方无需手动持久化。
struct NodeMutationService {

    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    let queryService: NodeQueryService
    private let logger = ConsoleLogger()

    // MARK: - 插入

    func insertAfter(nodeID: UUID, in pageID: UUID) async throws -> Node {
        logger.debug("开始在节点后插入, nodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let current = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        let nextSibling = queryService.nextSibling(of: nodeID, in: nodes)
        let newSortIndex: Double
        if let next = nextSibling {
            newSortIndex = SortIndexPolicy.indexBetween(before: current.sortIndex, after: next.sortIndex)
        } else {
            newSortIndex = SortIndexPolicy.indexAfter(last: current.sortIndex)
        }

        let newNode = Node(
            id: UUID(), pageID: pageID,
            parentNodeID: current.parentNodeID,
            title: "", depth: current.depth,
            sortIndex: newSortIndex, isCollapsed: false,
            createdAt: Date(), updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        let emptyBlock = Block(
            id: UUID(), nodeID: newNode.id, type: .text,
            content: "", sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)
        logger.info("节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }

    func insertChild(nodeID: UUID, in pageID: UUID) async throws -> Node {
        logger.debug("开始插入子节点, parentNodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let parentNode = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        let existingChildren = queryService.children(of: nodeID, in: nodes)
        let lastChildIndex = existingChildren.map(\.sortIndex).max()
        let newSortIndex = lastChildIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        let newNode = Node(
            id: UUID(), pageID: pageID,
            parentNodeID: nodeID,
            title: "", depth: parentNode.depth + 1,
            sortIndex: newSortIndex, isCollapsed: false,
            createdAt: Date(), updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        let emptyBlock = Block(
            id: UUID(), nodeID: newNode.id, type: .text,
            content: "", sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)
        logger.info("子节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }
}
```

**Git commit message：**

```
feat: implement NodeMutationService insertAfter and insertChild
```

**解释：**

- `insertAfter` 新节点继承当前节点的 `parentNodeID` 和 `depth`（同级），并自动创建一个空 text Block。新节点排在当前节点与其下一个同级之间（`indexBetween`），或追加末尾（`indexAfter`）。
- `insertChild` 让新节点成为指定节点的最后一个子节点，`depth = parent.depth + 1`。同样自动创建空 Block。
- 两者共同设计原则：创建节点时即创建 Block，保证 UI 层每个节点都有内容区域可编辑。

---

## M4-13 NodeMutationService.delete

**分支：** `feature/m4-node-mutation-service`  
**文件：** `Features/NodeEditor/Services/NodeMutationService.swift`（追加）

```swift
extension NodeMutationService {
    func delete(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("开始删除节点, nodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let descendants = queryService.descendants(of: nodeID, in: nodes)
        let allIDs = [nodeID] + descendants.map(\.id)
        for id in allIDs {
            try await blockRepository.deleteAll(in: id)
            try await nodeRepository.delete(by: id)
        }
        logger.info("节点删除成功, nodeID=\(nodeID), 共 \(allIDs.count) 个", function: #function)
    }
}
```

**Git commit message：**

```
feat: implement NodeMutationService.delete with cascade
```

**解释：**

- 删除顺序：先删 Block，再删 Node，从最内层到最外层，避免孤儿数据。
- `descendants` 用 BFS 找出全部子孙（不含自身），`allIDs` 把自身也加进去，确保自身的 Block 和节点本身也被清理。
- MVP 策略：级联删除所有子孙，不做"提升子节点"的复杂逻辑，行为直观，实现简单。

---

## M4-14 NodeMutationService.moveUp 与 moveDown

**分支：** `feature/m4-node-mutation-service`  
**文件：** `Features/NodeEditor/Services/NodeMutationService.swift`（追加）

```swift
extension NodeMutationService {
    func moveUp(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("上移节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let prev = queryService.previousSibling(of: nodeID, in: nodes) else { return }

        var updatedNode = node
        var updatedPrev = prev
        updatedNode.sortIndex = prev.sortIndex
        updatedPrev.sortIndex = node.sortIndex
        updatedNode.updatedAt = Date()
        updatedPrev.updatedAt = Date()

        try await nodeRepository.update(updatedNode)
        try await nodeRepository.update(updatedPrev)
        logger.info("节点上移成功, nodeID=\(nodeID)", function: #function)
    }

    func moveDown(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("下移节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let next = queryService.nextSibling(of: nodeID, in: nodes) else { return }

        var updatedNode = node
        var updatedNext = next
        updatedNode.sortIndex = next.sortIndex
        updatedNext.sortIndex = node.sortIndex
        updatedNode.updatedAt = Date()
        updatedNext.updatedAt = Date()

        try await nodeRepository.update(updatedNode)
        try await nodeRepository.update(updatedNext)
        logger.info("节点下移成功, nodeID=\(nodeID)", function: #function)
    }
}
```

**Git commit message：**

```
feat: implement NodeMutationService moveUp and moveDown
```

**解释：**

- `moveUp` / `moveDown` 交换相邻兄弟节点的 `sortIndex`，是最简单可靠的移动实现，不需要重新计算插入位置。
- 过滤逻辑通过 `previousSibling` / `nextSibling` 完成，只在同级兄弟间操作，不会跨层移动。
- 没有前/后兄弟节点时直接 `return`，为 noop，不抛出错误。

---

## M4-15 NodeMutationService.indent 与 outdent

**分支：** `feature/m4-node-mutation-service`  
**文件：** `Features/NodeEditor/Services/NodeMutationService.swift`（追加）

```swift
extension NodeMutationService {
    func indent(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("缩进节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let newParent = queryService.previousSibling(of: nodeID, in: nodes) else { return }

        let existingChildren = queryService.children(of: newParent.id, in: nodes)
        let lastIndex = existingChildren.map(\.sortIndex).max()
        let newSortIndex = lastIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        var updatedNode = node
        updatedNode.parentNodeID = newParent.id
        updatedNode.depth = newParent.depth + 1
        updatedNode.sortIndex = newSortIndex
        updatedNode.updatedAt = Date()
        try await nodeRepository.update(updatedNode)

        let descendants = queryService.descendants(of: nodeID, in: nodes)
        for var desc in descendants {
            desc.depth += 1
            desc.updatedAt = Date()
            try await nodeRepository.update(desc)
        }
        logger.info("节点缩进成功, nodeID=\(nodeID)", function: #function)
    }

    func outdent(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("反缩进节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let parentNode = queryService.parent(of: nodeID, in: nodes) else { return }

        let nextOfParent = queryService.nextSibling(of: parentNode.id, in: nodes)
        let newSortIndex: Double
        if let next = nextOfParent {
            newSortIndex = SortIndexPolicy.indexBetween(before: parentNode.sortIndex, after: next.sortIndex)
        } else {
            newSortIndex = SortIndexPolicy.indexAfter(last: parentNode.sortIndex)
        }

        var updatedNode = node
        updatedNode.parentNodeID = parentNode.parentNodeID
        updatedNode.depth = max(0, node.depth - 1)
        updatedNode.sortIndex = newSortIndex
        updatedNode.updatedAt = Date()
        try await nodeRepository.update(updatedNode)

        let descendants = queryService.descendants(of: nodeID, in: nodes)
        for var desc in descendants {
            desc.depth = max(0, desc.depth - 1)
            desc.updatedAt = Date()
            try await nodeRepository.update(desc)
        }
        logger.info("节点反缩进成功, nodeID=\(nodeID)", function: #function)
    }
}
```

**Git commit message：**

```
feat: implement NodeMutationService indent and outdent
```

**解释：**

- `indent`：成为前一个同级节点的最后一个子节点，`depth + 1`，并批量更新所有子孙的 depth。
- `outdent`：提升到原父节点的同级，排在原父节点之后，`depth - 1`，同样批量更新子孙。
- `max(0, depth - 1)` 防止深度降到负数，是防御性编程的基本要求。

---

## M4-16 NodeMutationService.toggleCollapse 与 updateTitle

**分支：** `feature/m4-node-mutation-service`  
**文件：** `Features/NodeEditor/Services/NodeMutationService.swift`（追加）

```swift
extension NodeMutationService {
    func toggleCollapse(nodeID: UUID) async throws {
        logger.debug("切换折叠状态, nodeID=\(nodeID)", function: #function)
        guard var node = try await nodeRepository.fetch(by: nodeID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        node.isCollapsed.toggle()
        node.updatedAt = Date()
        try await nodeRepository.update(node)
        logger.info("折叠状态更新成功, nodeID=\(nodeID)", function: #function)
    }

    func updateTitle(nodeID: UUID, title: String) async throws {
        logger.debug("更新节点标题, nodeID=\(nodeID)", function: #function)
        guard var node = try await nodeRepository.fetch(by: nodeID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        node.title = title
        node.updatedAt = Date()
        try await nodeRepository.update(node)
        logger.info("节点标题更新成功, nodeID=\(nodeID)", function: #function)
    }
}
```

**Git commit message：**

```
feat: implement NodeMutationService toggleCollapse and updateTitle
```

**解释：**

- `toggleCollapse` 直接取反 `isCollapsed`，不需要传参，每次调用即切换状态。
- `updateTitle` 是高频调用方法，由 `NodePersistenceCoordinator` 的 debounce 包裹后写入，确保不每次击键都触发存储。
- 两者都只需要 `fetch(by:)` 单条记录，不需要加载整个页面的 Node 列表，比其他 mutation 方法开销更小。

```swift
import Foundation

/// 负责执行 Node 结构变更操作。
/// 每个方法都会直接读写 Repository，调用方无需手动持久化。
struct NodeMutationService {

    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    let queryService: NodeQueryService
    private let logger = ConsoleLogger()

    // MARK: - 插入

    func insertAfter(nodeID: UUID, in pageID: UUID) async throws -> Node {
        logger.debug("开始在节点后插入, nodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let current = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        let nextSibling = queryService.nextSibling(of: nodeID, in: nodes)
        let newSortIndex: Double
        if let next = nextSibling {
            newSortIndex = SortIndexPolicy.indexBetween(before: current.sortIndex, after: next.sortIndex)
        } else {
            newSortIndex = SortIndexPolicy.indexAfter(last: current.sortIndex)
        }

        let newNode = Node(
            id: UUID(),
            pageID: pageID,
            parentNodeID: current.parentNodeID,
            title: "",
            depth: current.depth,
            sortIndex: newSortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        // 自动为新节点创建一个空 text Block
        let emptyBlock = Block(
            id: UUID(),
            nodeID: newNode.id,
            type: .text,
            content: "",
            sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(),
            updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)

        logger.info("节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }

    func insertChild(nodeID: UUID, in pageID: UUID) async throws -> Node {
        logger.debug("开始插入子节点, parentNodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let parentNode = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        let existingChildren = queryService.children(of: nodeID, in: nodes)
        let lastChildIndex = existingChildren.map(\.sortIndex).max()
        let newSortIndex = lastChildIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        let newNode = Node(
            id: UUID(),
            pageID: pageID,
            parentNodeID: nodeID,
            title: "",
            depth: parentNode.depth + 1,
            sortIndex: newSortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepository.create(newNode)

        let emptyBlock = Block(
            id: UUID(),
            nodeID: newNode.id,
            type: .text,
            content: "",
            sortIndex: SortIndexPolicy.initialIndex(),
            createdAt: Date(),
            updatedAt: Date()
        )
        try await blockRepository.create(emptyBlock)

        logger.info("子节点插入成功, id=\(newNode.id)", function: #function)
        return newNode
    }

    // MARK: - 删除

    func delete(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("开始删除节点, nodeID=\(nodeID), pageID=\(pageID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        // 1. 找到全部子孙节点 id（不含自身）
        let descendants = queryService.descendants(of: nodeID, in: nodes)
        let allIDs = [nodeID] + descendants.map(\.id)
        // 2. 每个节点先删其 Block，再删节点本身
        for id in allIDs {
            try await blockRepository.deleteAll(in: id)
            try await nodeRepository.delete(by: id)
        }
        logger.info("节点删除成功, nodeID=\(nodeID), 共 \(allIDs.count) 个", function: #function)
    }

    // MARK: - 移动

    func moveUp(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("上移节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let prev = queryService.previousSibling(of: nodeID, in: nodes) else { return }

        var updatedNode = node
        var updatedPrev = prev
        updatedNode.sortIndex = prev.sortIndex
        updatedPrev.sortIndex = node.sortIndex
        updatedNode.updatedAt = Date()
        updatedPrev.updatedAt = Date()

        try await nodeRepository.update(updatedNode)
        try await nodeRepository.update(updatedPrev)
        logger.info("节点上移成功, nodeID=\(nodeID)", function: #function)
    }

    func moveDown(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("下移节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let next = queryService.nextSibling(of: nodeID, in: nodes) else { return }

        var updatedNode = node
        var updatedNext = next
        updatedNode.sortIndex = next.sortIndex
        updatedNext.sortIndex = node.sortIndex
        updatedNode.updatedAt = Date()
        updatedNext.updatedAt = Date()

        try await nodeRepository.update(updatedNode)
        try await nodeRepository.update(updatedNext)
        logger.info("节点下移成功, nodeID=\(nodeID)", function: #function)
    }

    // MARK: - 缩进 / 反缩进

    func indent(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("缩进节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let newParent = queryService.previousSibling(of: nodeID, in: nodes) else {
            // 没有前一个同级节点，无法缩进
            return
        }

        let existingChildren = queryService.children(of: newParent.id, in: nodes)
        let lastIndex = existingChildren.map(\.sortIndex).max()
        let newSortIndex = lastIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        var updatedNode = node
        updatedNode.parentNodeID = newParent.id
        updatedNode.depth = newParent.depth + 1
        updatedNode.sortIndex = newSortIndex
        updatedNode.updatedAt = Date()
        try await nodeRepository.update(updatedNode)

        // 批量更新所有子孙节点的 depth +1
        let descendants = queryService.descendants(of: nodeID, in: nodes)
        for var desc in descendants {
            desc.depth += 1
            desc.updatedAt = Date()
            try await nodeRepository.update(desc)
        }
        logger.info("节点缩进成功, nodeID=\(nodeID)", function: #function)
    }

    func outdent(nodeID: UUID, in pageID: UUID) async throws {
        logger.debug("反缩进节点, nodeID=\(nodeID)", function: #function)
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        guard let node = nodes.first(where: { $0.id == nodeID }) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        guard let parentNode = queryService.parent(of: nodeID, in: nodes) else {
            // 已在根层，无法反缩进
            return
        }

        let nextOfParent = queryService.nextSibling(of: parentNode.id, in: nodes)
        let newSortIndex: Double
        if let next = nextOfParent {
            newSortIndex = SortIndexPolicy.indexBetween(
                before: parentNode.sortIndex,
                after: next.sortIndex
            )
        } else {
            newSortIndex = SortIndexPolicy.indexAfter(last: parentNode.sortIndex)
        }

        var updatedNode = node
        updatedNode.parentNodeID = parentNode.parentNodeID
        updatedNode.depth = max(0, node.depth - 1)
        updatedNode.sortIndex = newSortIndex
        updatedNode.updatedAt = Date()
        try await nodeRepository.update(updatedNode)

        // 批量更新所有子孙节点的 depth -1
        let descendants = queryService.descendants(of: nodeID, in: nodes)
        for var desc in descendants {
            desc.depth = max(0, desc.depth - 1)
            desc.updatedAt = Date()
            try await nodeRepository.update(desc)
        }
        logger.info("节点反缩进成功, nodeID=\(nodeID)", function: #function)
    }

    // MARK: - 折叠

    func toggleCollapse(nodeID: UUID) async throws {
        logger.debug("切换折叠状态, nodeID=\(nodeID)", function: #function)
        guard var node = try await nodeRepository.fetch(by: nodeID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        node.isCollapsed.toggle()
        node.updatedAt = Date()
        try await nodeRepository.update(node)
        logger.info("折叠状态更新成功, nodeID=\(nodeID)", function: #function)
    }

    // MARK: - 标题

    func updateTitle(nodeID: UUID, title: String) async throws {
        logger.debug("更新节点标题, nodeID=\(nodeID)", function: #function)
        guard var node = try await nodeRepository.fetch(by: nodeID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        node.title = title
        node.updatedAt = Date()
        try await nodeRepository.update(node)
        logger.info("节点标题更新成功, nodeID=\(nodeID)", function: #function)
    }
}
```

**Git commit message：**

```
feat: implement NodeMutationService with all structural operations
```

**解释：**

- `insertAfter` 新节点继承当前节点的 `parentNodeID` 和 `depth`，即与当前节点同级。同时自动创建一个空 text Block——这是键盘回车行为的核心实现，用户按回车后立刻能在新节点中输入。
- `indent` 的核心逻辑：找前一个同级节点作为新父节点，成为其最后一个子节点，然后批量将自身及所有子孙节点的 `depth + 1`。深度更新必须批量完成，否则子节点深度与父节点脱节。
- `outdent` 与 `indent` 对称：提升到原父节点的同级，排在原父节点之后，批量 `depth - 1`。`max(0, depth - 1)` 防止深度降到负数。
- `delete` 采用级联删除策略：先用 `descendants` 找到全部子孙，逐一删其 Block 再删节点本身。这与 M3 `DeletePageUseCase` 的策略保持一致——内容先于容器删除。
- `moveUp` / `moveDown` 交换相邻兄弟节点的 `sortIndex`，是最简单的移动实现。只在同级兄弟间交换，不会跨层移动。

---

## M4-17 BlockEditingService（addBlock / deleteBlock / updateContent）

**分支：** `feature/m4-block-editing-service`  
**文件：** `Features/NodeEditor/Services/BlockEditingService.swift`（新建）

```swift
import Foundation

/// 负责 Block 内容层的增删改排操作。
/// MVP 阶段只处理 .text 类型，POST 阶段扩展类型时在此添加逻辑。
struct BlockEditingService {

    let blockRepository: BlockRepositoryProtocol
    private let logger = ConsoleLogger()

    func addBlock(nodeID: UUID, type: BlockType) async throws -> Block {
        logger.debug("开始添加 Block, nodeID=\(nodeID), type=\(type)", function: #function)
        let existing = try await blockRepository.fetchAll(in: nodeID)
        let lastIndex = existing.map(\.sortIndex).max()
        let newSortIndex = lastIndex.map { SortIndexPolicy.indexAfter(last: $0) }
            ?? SortIndexPolicy.initialIndex()

        let block = Block(
            id: UUID(), nodeID: nodeID, type: type,
            content: "", sortIndex: newSortIndex,
            createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(block)
        logger.info("Block 添加成功, id=\(block.id)", function: #function)
        return block
    }

    func deleteBlock(blockID: UUID) async throws {
        logger.debug("开始删除 Block, blockID=\(blockID)", function: #function)
        try await blockRepository.delete(by: blockID)
        logger.info("Block 删除成功, blockID=\(blockID)", function: #function)
    }

    func updateContent(blockID: UUID, content: String) async throws {
        logger.debug("更新 Block 内容, blockID=\(blockID)", function: #function)
        guard var block = try await blockRepository.fetch(by: blockID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        block.content = content
        block.updatedAt = Date()
        try await blockRepository.update(block)
        logger.info("Block 内容更新成功, blockID=\(blockID)", function: #function)
    }
}
```

**Git commit message：**

```
feat: implement BlockEditingService addBlock, deleteBlock, updateContent
```

**解释：**

- `addBlock` 用 `SortIndexPolicy.indexAfter(last:)` 将新 Block 追加到末尾，与 Collection、Page 的创建策略一致。
- `updateContent` 是编辑器中最高频调用的方法，通过 `NodePersistenceCoordinator` 的 debounce 包裹后才写入存储，单次击键不直接触发 Repository 调用。

---

## M4-17b BlockEditingService.reorderBlock

**分支：** `feature/m4-block-editing-service`  
**文件：** `Features/NodeEditor/Services/BlockEditingService.swift`（追加）

```swift
extension BlockEditingService {
    func reorderBlock(blockID: UUID, newSortIndex: Double) async throws {
        logger.debug("调整 Block 排序, blockID=\(blockID), newSortIndex=\(newSortIndex)", function: #function)
        guard var block = try await blockRepository.fetch(by: blockID) else {
            throw AppError.repositoryError(RepositoryError.notFound)
        }
        block.sortIndex = newSortIndex
        block.updatedAt = Date()
        try await blockRepository.update(block)
        logger.info("Block 排序更新成功, blockID=\(blockID)", function: #function)
    }
}
```

**Git commit message：**

```
feat: implement BlockEditingService.reorderBlock
```

**解释：**

- `reorderBlock` 只修改 `sortIndex`，Block 的归属 Node 不可更改。
- MVP 阶段 UI 层暂未暴露 Block 排序入口，该方法为 POST 阶段拖拽排序预留，接口已稳定。

---

## M4-18 NodeEditorEngine

**分支：** `feature/m4-node-editor-engine`  
**文件：** `Features/NodeEditor/Engine/NodeEditorEngine.swift`

```swift
import Foundation

/// Node 编辑器的核心调度层。
/// 接收 NodeCommand / BlockCommand，路由到对应 Service 执行，
/// 执行完成后重新加载 Node 树并通知 ViewModel 更新。
@MainActor
class NodeEditorEngine: ObservableObject {

    let pageID: UUID
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    let mutationService: NodeMutationService
    let queryService: NodeQueryService
    let blockService: BlockEditingService

    @Published var editorNodes: [EditorNode] = []
    @Published var error: AppError?

    init(
        pageID: UUID,
        nodeRepository: NodeRepositoryProtocol,
        blockRepository: BlockRepositoryProtocol
    ) {
        self.pageID = pageID
        self.nodeRepository = nodeRepository
        self.blockRepository = blockRepository
        self.queryService = NodeQueryService()
        self.mutationService = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
        self.blockService = BlockEditingService(blockRepository: blockRepository)
    }

    // MARK: - 加载

    func loadNodes() async {
        do {
            let nodes = try await nodeRepository.fetchAll(in: pageID)
            var allBlocks: [Block] = []
            for node in nodes {
                let blocks = try await blockRepository.fetchAll(in: node.id)
                allBlocks.append(contentsOf: blocks)
            }
            let roots = queryService.buildTree(nodes: nodes, blocks: allBlocks)
            editorNodes = queryService.visibleNodes(from: roots)
        } catch {
            self.error = .repositoryError(error as? RepositoryError ?? RepositoryError.saveFailed(error))
        }
    }

    // MARK: - Node 命令分发

    func dispatch(_ command: NodeCommand) {
        Task {
            do {
                switch command {
                case .insertAfter(let nodeID):
                    _ = try await mutationService.insertAfter(nodeID: nodeID, in: pageID)
                case .insertChild(let nodeID):
                    _ = try await mutationService.insertChild(nodeID: nodeID, in: pageID)
                case .delete(let nodeID):
                    try await mutationService.delete(nodeID: nodeID, in: pageID)
                case .moveUp(let nodeID):
                    try await mutationService.moveUp(nodeID: nodeID, in: pageID)
                case .moveDown(let nodeID):
                    try await mutationService.moveDown(nodeID: nodeID, in: pageID)
                case .indent(let nodeID):
                    try await mutationService.indent(nodeID: nodeID, in: pageID)
                case .outdent(let nodeID):
                    try await mutationService.outdent(nodeID: nodeID, in: pageID)
                case .toggleCollapse(let nodeID):
                    try await mutationService.toggleCollapse(nodeID: nodeID)
                case .updateTitle(let nodeID, let title):
                    try await mutationService.updateTitle(nodeID: nodeID, title: title)
                }
                await loadNodes()
            } catch {
                self.error = error as? AppError
            }
        }
    }

    // MARK: - Block 命令分发

    func dispatch(_ command: BlockCommand) {
        Task {
            do {
                switch command {
                case .addBlock(let nodeID, let type):
                    _ = try await blockService.addBlock(nodeID: nodeID, type: type)
                case .deleteBlock(let blockID):
                    try await blockService.deleteBlock(blockID: blockID)
                case .updateContent(let blockID, let content):
                    try await blockService.updateContent(blockID: blockID, content: content)
                case .reorderBlock(let blockID, let newSortIndex):
                    try await blockService.reorderBlock(blockID: blockID, newSortIndex: newSortIndex)
                }
                await loadNodes()
            } catch {
                self.error = error as? AppError
            }
        }
    }
}
```

**Git commit message：**

```
feat: implement NodeEditorEngine with command dispatch
```

**解释：**

- `NodeEditorEngine` 是编辑器的"总线"，`PageEditorViewModel` 只与它对话，不直接调用 Service。层次关系：`ViewModel → Engine → Service → Repository`。
- `@MainActor` 确保 `@Published` 属性的更新发生在主线程，SwiftUI 视图能正确响应。
- `dispatch` 内部用 `Task { }` 将 `async throws` 的 Service 调用包装，每次命令执行完成后调用 `loadNodes()` 重建整棵树并刷新 `editorNodes`。这是 M4 的"重新加载"策略——简单可靠，M5 可优化为局部刷新。
- `loadNodes` 批量加载 Block：先取所有 Node，再逐个加载其 Block。MVP 阶段单页 Node 数量有限，性能可接受。
- 两个 `dispatch` 方法重载，Swift 编译器通过参数类型自动路由到 `NodeCommand` 或 `BlockCommand` 版本。

---

## M4-19 NodePersistenceCoordinator

**分支：** `feature/m4-persistence-coordinator`  
**文件：** `Features/NodeEditor/Services/NodePersistenceCoordinator.swift`

```swift
import Foundation

/// 管理 Node 编辑器的自动保存策略。
/// UI 层高频触发的内容变更（如逐字输入）通过此类的 debounce 机制
/// 延迟合并后再写入 Repository，避免每次击键都触发存储操作。
@MainActor
class NodePersistenceCoordinator {

    enum SaveState {
        case saved
        case saving
        case unsaved
    }

    private(set) var saveState: SaveState = .saved

    private let engine: NodeEditorEngine
    private var pendingBlockUpdates: [UUID: String] = [:]
    private var pendingTitleUpdates: [UUID: String] = [:]
    private var debounceTask: Task<Void, Never>?

    private let debounceInterval: Duration = .milliseconds(600)

    init(engine: NodeEditorEngine) {
        self.engine = engine
    }

    // MARK: - 触发延迟保存

    func scheduleContentUpdate(blockID: UUID, content: String) {
        pendingBlockUpdates[blockID] = content
        saveState = .unsaved
        scheduleFlush()
    }

    func scheduleTitleUpdate(nodeID: UUID, title: String) {
        pendingTitleUpdates[nodeID] = title
        saveState = .unsaved
        scheduleFlush()
    }

    private func scheduleFlush() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            await flush()
        }
    }

    // MARK: - 强制立即保存（退出/后台时调用）

    func flush() async {
        debounceTask?.cancel()
        guard !pendingBlockUpdates.isEmpty || !pendingTitleUpdates.isEmpty else {
            saveState = .saved
            return
        }

        let blockUpdatesSnapshot = pendingBlockUpdates
        let titleUpdatesSnapshot = pendingTitleUpdates
        saveState = .saving

        do {
            try await persist(blockUpdates: blockUpdatesSnapshot, titleUpdates: titleUpdatesSnapshot)
            await engine.loadNodes()
            clearPersistedSnapshots(
                blockUpdates: blockUpdatesSnapshot,
                titleUpdates: titleUpdatesSnapshot
            )

            if pendingBlockUpdates.isEmpty && pendingTitleUpdates.isEmpty {
                saveState = .saved
            } else {
                saveState = .unsaved
            }
        } catch {
            engine.error = .repositoryError(error as? RepositoryError ?? RepositoryError.saveFailed(error))
            saveState = .unsaved
        }
    }
}

private extension NodePersistenceCoordinator {
    func persist(
        blockUpdates: [UUID: String],
        titleUpdates: [UUID: String]
    ) async throws {
        for (blockID, content) in blockUpdates {
            guard var block = try await engine.blockRepository.fetch(by: blockID) else {
                throw RepositoryError.notFound
            }
            block.content = content
            block.updatedAt = Date()
            try await engine.blockRepository.update(block)
        }

        for (nodeID, title) in titleUpdates {
            guard var node = try await engine.nodeRepository.fetch(by: nodeID) else {
                throw RepositoryError.notFound
            }
            node.title = title
            node.updatedAt = Date()
            try await engine.nodeRepository.update(node)
        }
    }

    func clearPersistedSnapshots(
        blockUpdates: [UUID: String],
        titleUpdates: [UUID: String]
    ) {
        for (blockID, content) in blockUpdates where pendingBlockUpdates[blockID] == content {
            pendingBlockUpdates.removeValue(forKey: blockID)
        }

        for (nodeID, title) in titleUpdates where pendingTitleUpdates[nodeID] == title {
            pendingTitleUpdates.removeValue(forKey: nodeID)
        }
    }
}
```

**Git commit message：**

```
refactor: batch autosave persistence in NodePersistenceCoordinator
```

**解释：**

- Debounce 策略保持不变：每次用户输入触发 `scheduleContentUpdate` 或 `scheduleTitleUpdate`，将变更缓存在字典中，并重置定时器。只有用户停止输入 600ms 后才真正进入持久化阶段。同一 blockID/nodeID 的多次更新覆盖字典中的旧值，最终只保存最后一次内容。
- `flush()` 不再逐条调用 `engine.dispatch(...)`，而是直接使用 `engine` 持有的 Repository 批量更新快照，再统一执行一次 `engine.loadNodes()`。这样可以避免一次 flush 触发多次重载。
- `flush()` 基于快照保存，并且只移除“本次成功持久化且期间未被新输入覆盖”的缓存项。这样即使保存过程中又有新输入到来，也不会误删最新未保存内容。
- 保存失败时，`saveState` 保持为 `.unsaved`，并将错误写入 `engine.error`，页面层仍然可以继续展示未保存状态并由上层决定是否提示用户。

---

## M4-20 PageEditorViewModel

**分支：** `feature/m4-page-editor-viewmodel`  
**文件：** `Features/NodeEditor/ViewModels/PageEditorViewModel.swift`

```swift
import Foundation
import SwiftUI

@MainActor
class PageEditorViewModel: ObservableObject {

    let pageID: UUID
    let pageTitle: String

    @Published var visibleNodes: [EditorNode] = []
    @Published var focusedNodeID: UUID?
    @Published var error: AppError?

    private let engine: NodeEditorEngine
    let persistenceCoordinator: NodePersistenceCoordinator

    init(
        pageID: UUID,
        pageTitle: String,
        nodeRepository: NodeRepositoryProtocol,
        blockRepository: BlockRepositoryProtocol
    ) {
        self.pageID = pageID
        self.pageTitle = pageTitle
        let engine = NodeEditorEngine(
            pageID: pageID,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
        self.engine = engine
        self.persistenceCoordinator = NodePersistenceCoordinator(engine: engine)
    }

    // MARK: - 加载

    func loadPage() async {
        await engine.loadNodes()
        visibleNodes = engine.editorNodes
    }

    // MARK: - 命令转发

    func send(_ command: NodeCommand) {
        engine.dispatch(command)
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            visibleNodes = engine.editorNodes
            error = engine.error
        }
    }

    func send(_ command: BlockCommand) {
        engine.dispatch(command)
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            visibleNodes = engine.editorNodes
            error = engine.error
        }
    }

    // MARK: - 内容输入（走 debounce）

    func onTitleChanged(nodeID: UUID, title: String) {
        // 立即更新内存，保持 UI 响应流畅
        if let idx = visibleNodes.firstIndex(where: { $0.id == nodeID }) {
            visibleNodes[idx].title = title
        }
        persistenceCoordinator.scheduleTitleUpdate(nodeID: nodeID, title: title)
    }

    func onContentChanged(blockID: UUID, content: String) {
        for i in visibleNodes.indices {
            if let j = visibleNodes[i].blocks.firstIndex(where: { $0.id == blockID }) {
                visibleNodes[i].blocks[j].content = content
            }
        }
        persistenceCoordinator.scheduleContentUpdate(blockID: blockID, content: content)
    }

    // MARK: - 退出时强制保存

    func onDisappear() {
        Task {
            await persistenceCoordinator.flush()
        }
    }
}
```

**Git commit message：**

```
feat: implement PageEditorViewModel with load and command dispatch
```

**解释：**

- `PageEditorViewModel` 是 View 层唯一的数据入口，`PageEditorView` 不直接操作 Engine 或 Service。
- `onTitleChanged` 和 `onContentChanged` 采用"乐观更新"策略：先立即修改内存中的 `visibleNodes`（保证 UI 无延迟响应），再通过 `persistenceCoordinator` 延迟写入存储。这样用户感知不到任何输入卡顿。
- `send(_ command: NodeCommand)` 在 `engine.dispatch` 后加了 100ms 等待再同步 `visibleNodes`，给 Engine 内部的 `loadNodes` 异步操作足够完成时间。M5 阶段可改用更优雅的响应式模式替代。
- `onDisappear` 调用 `persistenceCoordinator.flush()` 时，现在会真正等待本轮批量持久化完成，而不是只把保存请求异步发出去。这让退出页面或进入后台时的数据安全语义更可靠。

---

## M4-21 PageEditorView

**分支：** `feature/m4-page-editor-view`  
**文件：** `Features/NodeEditor/Views/PageEditorView.swift`

```swift
import SwiftUI

struct PageEditorView: View {

    @StateObject var viewModel: PageEditorViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.visibleNodes) { node in
                    NodeRowView(
                        node: node,
                        onTitleChanged: { title in
                            viewModel.onTitleChanged(nodeID: node.id, title: title)
                        },
                        onContentChanged: { blockID, content in
                            viewModel.onContentChanged(blockID: blockID, content: content)
                        },
                        onCommand: { command in
                            viewModel.send(command)
                        }
                    )
                }

                // 底部空白点击区域：在末尾插入新节点
                Color.clear
                    .frame(height: 200)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let lastNode = viewModel.visibleNodes.last {
                            viewModel.send(.insertAfter(nodeID: lastNode.id))
                        }
                    }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle(viewModel.pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPage()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .alert("错误", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("好") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
}
```

**Git commit message：**

```
feat: build PageEditorView with scroll list and empty tap area
```

**解释：**

- `LazyVStack` 代替 `VStack`，在 Node 数量较多时只渲染视口内的行，避免一次性实例化所有 `NodeRowView`。
- 底部 `Color.clear` 点击区域实现"点击页面空白处在末尾新建节点"的交互，与 Apple Notes 的行为一致。
- `.task` 在视图首次出现时触发 `loadPage()`，`.onDisappear` 触发强制保存，生命周期钩子完整。
- `@StateObject` 让 ViewModel 的生命周期与 View 绑定，不会因为父视图重渲染而被重建。调用方通过 `DependencyContainer.makePageEditorViewModel(...)` 获取实例。

---

## M4-22 NodeRowView

**分支：** `feature/m4-node-row-view`  
**文件：** `Features/NodeEditor/Views/NodeRowView.swift`

```swift
import SwiftUI

struct NodeRowView: View {

    let node: EditorNode
    let onTitleChanged: (String) -> Void
    let onContentChanged: (UUID, String) -> Void
    let onCommand: (NodeCommand) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 左侧缩进导轨
            NodeIndentationGuide(depth: node.depth)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 类型指示器
                    NodeTypeIndicator(depth: node.depth)

                    // 折叠控件（有子节点时显示）
                    if !node.children.isEmpty {
                        NodeCollapseControl(isCollapsed: node.isCollapsed) {
                            onCommand(.toggleCollapse(nodeID: node.id))
                        }
                    }

                    // 标题输入框
                    NodeContentEditor(
                        text: node.title,
                        font: TypographyTokens.nodeTitle(depth: node.depth),
                        placeholder: node.depth == 0 ? "标题" : "节点",
                        onTextChanged: { onTitleChanged($0) },
                        onReturn: { onCommand(.insertAfter(nodeID: node.id)) },
                        onBackspaceWhenEmpty: {
                            if node.depth > 0 {
                                onCommand(.outdent(nodeID: node.id))
                            } else {
                                onCommand(.delete(nodeID: node.id))
                            }
                        },
                        onTab: { onCommand(.indent(nodeID: node.id)) },
                        onShiftTab: { onCommand(.outdent(nodeID: node.id)) }
                    )
                }

                // Block 内容区（MVP 只有 text 类型）
                ForEach(node.blocks) { block in
                    NodeContentEditor(
                        text: block.content,
                        font: TypographyTokens.body,
                        placeholder: "内容",
                        onTextChanged: { onContentChanged(block.id, $0) },
                        onReturn: { onCommand(.insertAfter(nodeID: node.id)) },
                        onBackspaceWhenEmpty: { },
                        onTab: { },
                        onShiftTab: { }
                    )
                    .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
```

**Git commit message：**

```
feat: build NodeRowView with title, blocks, and indent guide
```

**解释：**

- `NodeRowView` 是编辑器的最小渲染单元，本身不持有状态，所有数据通过 `node: EditorNode` 传入，所有事件通过回调上报给 `PageEditorViewModel`。
- 标题行与 Block 内容区分开渲染：标题对应 Node 的 `title` 字段，Block 内容对应 `node.blocks` 数组，两者使用不同字体（`nodeTitle(depth:)` vs `body`）。
- 折叠控件 `NodeCollapseControl` 仅在 `node.children` 非空时渲染，叶子节点不显示折叠按钮，保持界面整洁。
- 回调命名遵循 SwiftUI 惯例：`on` 前缀表示事件响应，参数是触发事件所需的最小信息。

---

## M4-23 NodeContentEditor（UITextView 包装）

**分支：** `feature/m4-node-content-editor`  
**文件：** `Features/NodeEditor/Views/NodeContentEditor.swift`

```swift
import SwiftUI
import UIKit

/// UITextView 的 SwiftUI 包装，用于 Node 标题和 Block 内容的输入。
/// 支持自定义键盘行为：Return、Backspace（空时）、Tab、Shift+Tab。
struct NodeContentEditor: UIViewRepresentable {

    var text: String
    var font: Font
    var placeholder: String

    var onTextChanged: (String) -> Void
    var onReturn: () -> Void
    var onBackspaceWhenEmpty: () -> Void
    var onTab: () -> Void
    var onShiftTab: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if text.isEmpty {
            uiView.text = placeholder
            uiView.textColor = UIColor.placeholderText
        } else if uiView.text != text {
            uiView.text = text
            uiView.textColor = UIColor.label
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: NodeContentEditor

        init(_ parent: NodeContentEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            // 占位符状态下不上报内容变更
            guard textView.textColor != UIColor.placeholderText else { return }
            parent.onTextChanged(textView.text ?? "")
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            // 开始编辑时清除占位符
            if textView.textColor == UIColor.placeholderText {
                textView.text = ""
                textView.textColor = UIColor.label
            }
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            // Return 键：新建节点
            if text == "\n" {
                parent.onReturn()
                return false
            }
            // Backspace 且文本为空：触发反缩进或删除
            if text.isEmpty,
               let current = textView.text,
               current.isEmpty || textView.textColor == UIColor.placeholderText {
                parent.onBackspaceWhenEmpty()
                return false
            }
            return true
        }
    }
}
```

**Git commit message：**

```
feat: implement NodeContentEditor as UITextView wrapper
```

**解释：**

- SwiftUI 原生的 `TextField` 和 `TextEditor` 不支持拦截 Return 键和 Backspace 键的自定义行为，因此使用 `UIViewRepresentable` 包装 `UITextView`。
- `shouldChangeTextIn` 是拦截键盘输入的标准 UIKit 委托方法：`text == "\n"` 对应 Return，`text.isEmpty && current.isEmpty` 对应"当前文本为空时按 Backspace"。两种情况都返回 `false` 阻止默认行为，改由回调处理。
- `isScrollEnabled = false` 让 UITextView 随内容增长而撑高，配合外层 `LazyVStack` 实现多行自动展开。
- 占位符通过 `textColor = UIColor.placeholderText` 和清空 text 实现；`textViewDidBeginEditing` 在聚焦时清除占位符并还原颜色，`textViewDidChange` 在占位符状态下不上报变更，避免把占位符文字写入数据。

---

## M4-24 NodeIndentationGuide

**分支：** `feature/m4-node-ui-components`  
**文件：** `Features/NodeEditor/Views/NodeIndentationGuide.swift`

```swift
import SwiftUI

/// 根据 depth 渲染左侧缩进占位和层级竖线。
struct NodeIndentationGuide: View {

    let depth: Int

    private let indentWidth: CGFloat = 20
    private let lineWidth: CGFloat = 1

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<depth, id: \.self) { _ in
                ZStack(alignment: .leading) {
                    Color.clear
                        .frame(width: indentWidth)
                    Rectangle()
                        .fill(ColorTokens.separator.opacity(0.4))
                        .frame(width: lineWidth)
                        .padding(.leading, indentWidth / 2 - lineWidth / 2)
                }
            }
        }
    }
}
```

**Git commit message：**

```
feat: build NodeIndentationGuide visual component
```

**解释：**

- 每个 depth 层渲染一个 20pt 宽的占位区域，并在左侧居中位置画一条 1pt 竖线。depth 为 0 时不渲染任何占位，根节点没有缩进线。
- `opacity(0.4)` 使竖线颜色轻柔，不喧宾夺主，与 Notion、Bear 等应用的视觉风格一致。
- 用 `ForEach(0..<depth, id: \.self)` 逐层渲染竖线，不同层的线可以独立控制样式（POST 阶段可以按层上色）。

---

## M4-25 NodeCollapseControl

**分支：** `feature/m4-node-ui-components`  
**文件：** `Features/NodeEditor/Views/NodeCollapseControl.swift`

```swift
import SwiftUI

/// 折叠/展开控制按钮，仅在节点有子节点时由 NodeRowView 渲染。
struct NodeCollapseControl: View {

    let isCollapsed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
```

**Git commit message：**

```
feat: build NodeCollapseControl button
```

**解释：**

- `chevron.right`（折叠，箭头朝右）和 `chevron.down`（展开，箭头朝下）是大纲编辑器的业界标准图标。
- `.buttonStyle(.plain)` 去掉 SwiftUI 默认的点击样式，让按钮外观由自身控制。
- `.contentShape(Rectangle())` 确保整个 16×16 的框都是点击区域，提升点击体验。

---

## M4-26 NodeTypeIndicator

**分支：** `feature/m4-node-ui-components`  
**文件：** `Features/NodeEditor/Views/NodeTypeIndicator.swift`

```swift
import SwiftUI

/// 每行左侧的类型指示圆点，根据 depth 调整大小与填充样式。
/// depth 0 为实心圆（主标题级），其余为空心圆（子级节点）。
struct NodeTypeIndicator: View {

    let depth: Int

    private var size: CGFloat {
        depth == 0 ? 8 : 6
    }

    private var isFilled: Bool {
        depth == 0
    }

    var body: some View {
        Circle()
            .fill(isFilled ? ColorTokens.accent : Color.clear)
            .overlay(
                Circle()
                    .stroke(ColorTokens.accent.opacity(0.6), lineWidth: 1.5)
            )
            .frame(width: size, height: size)
    }
}
```

**Git commit message：**

```
feat: build NodeTypeIndicator with depth-aware styling
```

**解释：**

- 根节点（depth 0）用实心圆强调，深层节点用空心圆弱化，视觉上形成层级感。
- 颜色使用 `ColorTokens.accent`（暖金色），与 M1 配色方案一致，不硬编码颜色值。
- 整个组件是纯展示组件，没有交互，不需要 `Button` 包装。

---

## M4-27 DependencyContainer 更新

**分支：** `feature/m4-dependency-container`  
**文件：** `App/DependencyContainer.swift`（在 M3 基础上更新）

```swift
import Combine
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

    // MARK: - ViewModel 工厂方法

    func makePageEditorViewModel(pageID: UUID, pageTitle: String) -> PageEditorViewModel {
        PageEditorViewModel(
            pageID: pageID,
            pageTitle: pageTitle,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
    }
}
```

**Git commit message：**

```
feat: add NodeRepository and BlockRepository to DependencyContainer
```

**解释：**

- M3 阶段 `DependencyContainer` 已包含 `collectionRepository` 和 `pageRepository`，M4 补充 `nodeRepository` 和 `blockRepository`，四个 Repository 完整对齐数据层。
- `makePageEditorViewModel(pageID:pageTitle:)` 工厂方法让 `PageListScreen` 在导航时不需要手动组装 ViewModel 的依赖，调用侧简洁。
- 所有 Repository 以 Protocol 类型声明，测试时可注入 Mock。

---

## M4-28 DeletePageUseCase Block 级联补全

**分支：** `feature/m4-delete-page-cascade`  
**文件：** `Features/Pages/UseCases/DeletePageUseCase.swift`（在 M3 基础上更新）

```swift
import Foundation

struct DeletePageUseCase {
    let repository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol
    private let logger = ConsoleLogger()

    func execute(pageID: UUID) async throws {
        logger.debug("开始删除 Page（含级联）, id=\(pageID)", function: #function)
        // 1. 获取所有 Node
        let nodes = try await nodeRepository.fetchAll(in: pageID)
        // 2. 逐 Node 删除其关联 Block
        for node in nodes {
            try await blockRepository.deleteAll(in: node.id)
        }
        // 3. 删除所有 Node
        try await nodeRepository.deleteAll(in: pageID)
        // 4. 删除 Page 本身
        try await repository.delete(by: pageID)
        logger.info("Page 删除成功（含 \(nodes.count) 个 Node）, id=\(pageID)", function: #function)
    }
}
```

**Git commit message：**

```
feat: complete DeletePageUseCase with block cascade deletion
```

**解释：**

- M3 的 `DeletePageUseCase` 对 `nodeRepository.deleteAll` 使用了 `try?`，因为彼时 `NodeRepository` 尚未完整实现。M4 `NodeRepository` 与 `BlockRepository` 均完整实现后，`try?` 改为 `try await`，错误可正确向上传播。
- 在 M3 基础上新增 `blockRepository` 依赖，显式补全 Block 的级联删除：先逐 Node 删其关联 Block，再统一删 Node，最后删 Page 本身。删除顺序 Block → Node → Page，从最内层到最外层，确保不留孤儿数据。
- `pageRepository` 属性名统一为 `repository`，与 Collection、Page 其他 UseCase 的命名保持一致。
- 添加 `ConsoleLogger` 日志，与其他 UseCase 保持一致。

---

## M4-29 AddNodeButton

**分支：** `feature/m4-node-row-view`（与 M4-15 同分支）  
**文件：** `Features/NodeEditor/Views/AddNodeButton.swift`

```swift
import SwiftUI

/// 行末的加号按钮，点击后在该节点之后插入一个新同级节点。
/// 在 NodeRowView 中悬停或长按时显示，MVP 阶段始终可见。
struct AddNodeButton: View {

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus.circle")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(ColorTokens.textSecondary.opacity(0.6))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
```

将 `AddNodeButton` 集成到 `NodeRowView` 的 HStack 末尾：

```swift
// NodeRowView 的 body HStack 末尾追加
HStack(spacing: 6) {
    NodeTypeIndicator(depth: node.depth)
    if !node.children.isEmpty {
        NodeCollapseControl(isCollapsed: node.isCollapsed) {
            onCommand(.toggleCollapse(nodeID: node.id))
        }
    }
    NodeContentEditor( /* ... */ )
    Spacer()
    AddNodeButton {
        onCommand(.insertAfter(nodeID: node.id))
    }
}
```

**Git commit message：**

```
feat: add AddNodeButton to NodeRowView
```

**解释：**

- `AddNodeButton` 封装为独立组件，`NodeRowView` 只需传入 `onTap` 回调，解耦清晰。
- MVP 阶段按钮始终可见，不做悬停显隐逻辑（交互打磨留 M5）。
- 点击效果等同于键盘 Return 键：`insertAfter(nodeID: node.id)`。

---

## M4-30 键盘 Return → insertAfter 行为

**分支：** `feature/m4-keyboard-behaviors`  
**文件：** `Features/NodeEditor/Views/NodeContentEditor.swift`（在 M4-16 基础上确认集成）

键盘 Return 行为已在 M4-16 的 `NodeContentEditor` 中实现：

```swift
func textView(
    _ textView: UITextView,
    shouldChangeTextIn range: NSRange,
    replacementText text: String
) -> Bool {
    if text == "\n" {
        parent.onReturn()   // → onCommand(.insertAfter(nodeID: node.id))
        return false
    }
    // ...
}
```

`NodeRowView` 中标题编辑器的 `onReturn` 回调：

```swift
NodeContentEditor(
    // ...
    onReturn: { onCommand(.insertAfter(nodeID: node.id)) },
    // ...
)
```

**Git commit message：**

```
feat: wire keyboard Return to insertAfter node command
```

**解释：**

- Return 键触发 `insertAfter`，新节点继承当前 depth，成为当前节点的下一个同级节点，并自动获得焦点（焦点管理在 M5 完善，M4 阶段新节点创建后依赖用户手动点击）。
- `return false` 阻止 UITextView 插入换行符，确保标题输入区始终是单行。
- Block 内容编辑器同样接入 `onReturn`，行为与标题一致：在 Node 层面新建节点而非在 Block 内换行（这是大纲编辑器的约定，Rich text 的段落管理留 POST 阶段）。

---

## M4-31 键盘 Backspace 空节点行为

**分支：** `feature/m4-keyboard-behaviors`  
**文件：** `Features/NodeEditor/Views/NodeContentEditor.swift`（在 M4-16 基础上确认集成）

Backspace 空节点行为已在 M4-16 中实现：

```swift
if text.isEmpty,
   let current = textView.text,
   current.isEmpty || textView.textColor == UIColor.placeholderText {
    parent.onBackspaceWhenEmpty()
    return false
}
```

`NodeRowView` 中 `onBackspaceWhenEmpty` 回调按 depth 决策：

```swift
NodeContentEditor(
    // ...
    onBackspaceWhenEmpty: {
        if node.depth > 0 {
            onCommand(.outdent(nodeID: node.id))
        } else {
            onCommand(.delete(nodeID: node.id))
        }
    },
    // ...
)
```

**Git commit message：**

```
feat: wire keyboard Backspace on empty node to outdent or delete
```

**解释：**

- 有父节点（depth > 0）时：Backspace 触发 `outdent`，提升层级，符合大纲编辑器"退格 = 减少缩进"的直觉。
- 根节点（depth == 0）时：Backspace 触发 `delete`，删除当前空节点。
- 非空节点时 `shouldChangeTextIn` 返回 `true`，交由 UITextView 处理普通退格，不影响正常编辑。

---

## M4-32 键盘 Tab → indent 行为

**分支：** `feature/m4-keyboard-behaviors`  
**文件：** `Features/NodeEditor/Views/NodeContentEditor.swift`（补充 Tab 支持）

在 `NodeContentEditor.Coordinator` 中拦截 Tab 键：

```swift
// 在 shouldChangeTextIn 中补充
// Tab 键的 replacementText 在 iOS 软键盘上不会直接触发，
// 需通过 UIKeyCommand 注册，或通过工具栏按钮触发。
// MVP 阶段通过 NodeRowView 的工具栏按钮实现，键盘快捷键留 M5。
```

`NodeRowView` 中 `onTab` 回调（工具栏按钮触发）：

```swift
NodeContentEditor(
    // ...
    onTab: { onCommand(.indent(nodeID: node.id)) },
    // ...
)
```

MVP 阶段在 `PageEditorView` 底部追加简易工具栏：

```swift
// PageEditorView body 底部，键盘弹起时显示
VStack {
    ScrollView { /* ... */ }
    HStack(spacing: 24) {
        Button("⇥") { /* indent focused node */ }
        Button("⇤") { /* outdent focused node */ }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(ColorTokens.backgroundSecondary)
}
```

**Git commit message：**

```
feat: wire Tab to indent via toolbar button
```

**解释：**

- iOS 软键盘不原生支持 Tab 键触发 `shouldChangeTextIn`，需要通过工具栏按钮（keyboard accessory）或 `UIKeyCommand`（外接键盘）实现。
- MVP 阶段用底部工具栏按钮实现，外接键盘的 `UIKeyCommand` 绑定留 M5 完善。
- `onTab` 回调保留在 `NodeContentEditor` 接口上，即便 MVP 暂不通过键盘触发，API 也保持一致，M5 可直接接入。

---

## M4-33 键盘 Shift+Tab → outdent 行为

**分支：** `feature/m4-keyboard-behaviors`  
**文件：** `Features/NodeEditor/Views/NodeContentEditor.swift`（同 M4-25）

`NodeRowView` 中 `onShiftTab` 回调（工具栏按钮触发）：

```swift
NodeContentEditor(
    // ...
    onShiftTab: { onCommand(.outdent(nodeID: node.id)) },
    // ...
)
```

**Git commit message：**

```
feat: wire Shift+Tab to outdent via toolbar button
```

**解释：**

- Shift+Tab 与 Tab 对称，行为是 `outdent`。
- 工具栏中 indent / outdent 两个按钮并排，操作反馈即时：按钮触发命令 → Engine 执行 → `loadNodes` 刷新 → ViewModel 更新 → 视图重渲染。
- `onShiftTab` 在 `NodeContentEditor` 接口上保留，供 M5 阶段外接键盘 `UIKeyCommand` 接入。

---

---

## M4-34 RootView 更新（接入 PageEditorView）

**文件：** `App/AppRouter.swift`（更新 `AppRoute.nodeEditor` 关联值）

```swift
import Foundation

enum AppRoute: Hashable {
    case pageList(collectionID: UUID, collectionTitle: String)
    case nodeEditor(pageID: UUID, pageTitle: String)   // 新增 pageTitle
}
```

**文件：** `App/RootView.swift`（替换 `.nodeEditor` 占位 Text）

```swift
import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                repository: dependencyContainer.collectionRepository
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .pageList(let collectionID, let collectionTitle):
                    PageListScreen(
                        collectionID: collectionID,
                        collectionTitle: collectionTitle,
                        pageRepository: dependencyContainer.pageRepository,
                        nodeRepository: dependencyContainer.nodeRepository
                    )
                case .nodeEditor(let pageID, let pageTitle):
                    PageEditorView(
                        viewModel: dependencyContainer.makePageEditorViewModel(
                            pageID: pageID,
                            pageTitle: pageTitle
                        )
                    )
                }
            }
        }
        .environmentObject(router)
    }
}
```

**文件：** `Features/Pages/Views/PageListScreen.swift`（更新 `router.navigate` 调用，传入 `pageTitle`）

```swift
// 将 M3 中的：
router.navigate(to: .nodeEditor(pageID: page.id))

// 改为：
router.navigate(to: .nodeEditor(pageID: page.id, pageTitle: page.title))
```

**Git commit message：**

```
feat: wire PageEditorView into RootView navigation
```

**解释：**

- M3 的 `AppRoute.nodeEditor` 只携带 `pageID`，但 `PageEditorView` 初始化时需要 `pageTitle` 用于 `navigationTitle`。若在 `PageEditorView` 内部再根据 `pageID` 发起查询来取标题，会增加一次异步 IO 且 `navigationTitle` 会有短暂空白。最简洁的做法是在 `AppRoute.nodeEditor` 关联值中直接携带 `pageTitle`，`PageListScreen` 在触发导航时已经持有 `page.title`，无额外开销。
- `PageListScreen` 只改 `router.navigate` 这一行，其余代码不动，改动范围极小。
- `dependencyContainer.makePageEditorViewModel(pageID:pageTitle:)` 是 M4-27 中已定义的工厂方法，这里直接调用，`RootView` 不需要感知 `NodeRepository` 和 `BlockRepository` 的细节。

---

## M4-35~50 单元测试与集成测试



---

### `Tests/UnitTests/Mocks/MockNodeRepository.swift`

```swift
import Foundation
@testable import Notte

actor MockNodeRepository: NodeRepositoryProtocol {

    private var store: [UUID: Node] = [:]

    func fetchAll(in pageID: UUID) async throws -> [Node] {
        store.values.filter { $0.pageID == pageID }
                    .sorted { $0.sortIndex < $1.sortIndex }
    }

    func fetch(by id: UUID) async throws -> Node? {
        store[id]
    }

    func create(_ node: Node) async throws {
        store[node.id] = node
    }

    func update(_ node: Node) async throws {
        guard store[node.id] != nil else {
            throw RepositoryError.notFound
        }
        store[node.id] = node
    }

    func delete(by id: UUID) async throws {
        guard store[id] != nil else {
            throw RepositoryError.notFound
        }
        store.removeValue(forKey: id)
    }

    func deleteAll(in pageID: UUID) async throws {
        store = store.filter { $0.value.pageID != pageID }
    }
}
```

---

### `Tests/UnitTests/Mocks/MockBlockRepository.swift`

```swift
import Foundation
@testable import Notte

actor MockBlockRepository: BlockRepositoryProtocol {

    private var store: [UUID: Block] = [:]

    func fetchAll(in nodeID: UUID) async throws -> [Block] {
        store.values.filter { $0.nodeID == nodeID }
                    .sorted { $0.sortIndex < $1.sortIndex }
    }

    func fetch(by id: UUID) async throws -> Block? {
        store[id]
    }

    func create(_ block: Block) async throws {
        store[block.id] = block
    }

    func update(_ block: Block) async throws {
        guard store[block.id] != nil else {
            throw RepositoryError.notFound
        }
        store[block.id] = block
    }

    func delete(by id: UUID) async throws {
        guard store[id] != nil else {
            throw RepositoryError.notFound
        }
        store.removeValue(forKey: id)
    }

    func deleteAll(in nodeID: UUID) async throws {
        store = store.filter { $0.value.nodeID != nodeID }
    }
}
```

**Git commit message：**

```
test: add MockNodeRepository and MockBlockRepository
```

---

---

以下各测试 section 对应开发计划中 13 个独立测试 issue（M4-29～41）以及 2 个集成测试 issue（M4-42～43）。

---

### M4-29／M4-30：`Tests/UnitTests/NodeQueryServiceTests.swift`

对应 issue：`Add NodeQueryService.buildTree unit tests` + `Add NodeQueryService.visibleNodes unit tests`

```swift
import XCTest
@testable import Notte

final class NodeQueryServiceTests: XCTestCase {

    var service: NodeQueryService!
    let pageID = UUID()

    override func setUp() {
        service = NodeQueryService()
    }

    func test_buildTree_flatList_returnsRootNodes() {
        let root1 = makeNode(depth: 0, sortIndex: 1000)
        let root2 = makeNode(depth: 0, sortIndex: 2000)
        let roots = service.buildTree(nodes: [root1, root2], blocks: [])
        XCTAssertEqual(roots.count, 2)
    }

    func test_buildTree_withChild_attachesCorrectly() {
        let parentID = UUID()
        let parent = makeNode(id: parentID, depth: 0, sortIndex: 1000)
        let child = makeNode(depth: 1, sortIndex: 1000, parentNodeID: parentID)
        let roots = service.buildTree(nodes: [parent, child], blocks: [])
        XCTAssertEqual(roots.count, 1)
        XCTAssertEqual(roots.first?.children.count, 1)
    }

    func test_visibleNodes_collapsedParent_hidesChildren() {
        let parentID = UUID()
        var parent = makeNode(id: parentID, depth: 0, sortIndex: 1000)
        parent.isCollapsed = true
        let child = makeNode(depth: 1, sortIndex: 1000, parentNodeID: parentID)
        let roots = service.buildTree(nodes: [parent, child], blocks: [])
        let visible = service.visibleNodes(from: roots)
        XCTAssertEqual(visible.count, 1, "折叠时子节点不应出现在可见列表中")
    }

    func test_visibleNodes_expandedParent_showsChildren() {
        let parentID = UUID()
        let parent = makeNode(id: parentID, depth: 0, sortIndex: 1000)
        let child = makeNode(depth: 1, sortIndex: 1000, parentNodeID: parentID)
        let roots = service.buildTree(nodes: [parent, child], blocks: [])
        let visible = service.visibleNodes(from: roots)
        XCTAssertEqual(visible.count, 2)
    }

    func test_descendants_returnsAllDescendants() {
        let rootID = UUID()
        let childID = UUID()
        let root = makeNode(id: rootID, depth: 0, sortIndex: 1000)
        let child = makeNode(id: childID, depth: 1, sortIndex: 1000, parentNodeID: rootID)
        let grandchild = makeNode(depth: 2, sortIndex: 1000, parentNodeID: childID)
        let result = service.descendants(of: rootID, in: [root, child, grandchild])
        XCTAssertEqual(result.count, 2, "子孙节点应包含直接子节点和孙节点")
    }

    func test_buildTree_injectsBlocksIntoNode() {
        let nodeID = UUID()
        let node = makeNode(id: nodeID, depth: 0, sortIndex: 1000)
        let block = Block(
            id: UUID(), nodeID: nodeID, type: .text,
            content: "hello", sortIndex: 1000, createdAt: Date(), updatedAt: Date()
        )
        let roots = service.buildTree(nodes: [node], blocks: [block])
        XCTAssertEqual(roots.first?.blocks.count, 1)
        XCTAssertEqual(roots.first?.blocks.first?.content, "hello")
    }

    // MARK: - Helpers

    private func makeNode(
        id: UUID = UUID(),
        depth: Int,
        sortIndex: Double,
        parentNodeID: UUID? = nil
    ) -> Node {
        Node(
            id: id,
            pageID: pageID,
            parentNodeID: parentNodeID,
            title: "节点",
            depth: depth,
            sortIndex: sortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
```

**Git commit message：**

```
test: add NodeQueryService unit tests
```

---

### M4-31～36：`Tests/UnitTests/NodeMutationServiceTests.swift`

对应 issue：`insertAfter` / `indent` / `outdent` / `delete cascade` / `moveUp/moveDown` / `toggleCollapse` 六个测试 issue

```swift
import XCTest
@testable import Notte

final class NodeMutationServiceTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var service: NodeMutationService!
    let pageID = UUID()

    override func setUp() {
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        service = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
    }

    func test_insertAfter_createsNodeWithSameLevelAndEmptyBlock() async throws {
        let existing = makeNode(depth: 0, sortIndex: 1000)
        try await nodeRepository.create(existing)

        let newNode = try await service.insertAfter(nodeID: existing.id, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        XCTAssertEqual(nodes.count, 2)
        XCTAssertEqual(newNode.depth, existing.depth)
        XCTAssertGreaterThan(newNode.sortIndex, existing.sortIndex)

        let blocks = try await blockRepository.fetchAll(in: newNode.id)
        XCTAssertEqual(blocks.count, 1, "新节点应自动创建一个空 Block")
    }

    func test_indent_changesParentAndDepth() async throws {
        let parentID = UUID()
        let prev = makeNode(id: parentID, depth: 0, sortIndex: 1000)
        let target = makeNode(depth: 0, sortIndex: 2000)
        try await nodeRepository.create(prev)
        try await nodeRepository.create(target)

        try await service.indent(nodeID: target.id, in: pageID)

        let updated = try await nodeRepository.fetch(by: target.id)!
        XCTAssertEqual(updated.parentNodeID, parentID)
        XCTAssertEqual(updated.depth, 1)
    }

    func test_outdent_movesNodeToRootLevel() async throws {
        let rootID = UUID()
        let root = makeNode(id: rootID, depth: 0, sortIndex: 1000)
        let child = makeNode(depth: 1, sortIndex: 1000, parentNodeID: rootID)
        try await nodeRepository.create(root)
        try await nodeRepository.create(child)

        try await service.outdent(nodeID: child.id, in: pageID)

        let updated = try await nodeRepository.fetch(by: child.id)!
        XCTAssertNil(updated.parentNodeID)
        XCTAssertEqual(updated.depth, 0)
    }

    func test_delete_cascadesChildrenAndBlocks() async throws {
        let parentID = UUID()
        let parent = makeNode(id: parentID, depth: 0, sortIndex: 1000)
        let child = makeNode(depth: 1, sortIndex: 1000, parentNodeID: parentID)
        try await nodeRepository.create(parent)
        try await nodeRepository.create(child)

        let block = makeBlock(nodeID: parentID)
        try await blockRepository.create(block)

        try await service.delete(nodeID: parentID, in: pageID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        XCTAssertTrue(nodes.isEmpty, "父节点和子节点应全部被删除")

        let blocks = try await blockRepository.fetchAll(in: parentID)
        XCTAssertTrue(blocks.isEmpty, "关联 Block 应被级联删除")
    }

    func test_toggleCollapse_togglesState() async throws {
        let node = makeNode(depth: 0, sortIndex: 1000)
        try await nodeRepository.create(node)

        try await service.toggleCollapse(nodeID: node.id)
        let toggled = try await nodeRepository.fetch(by: node.id)!
        XCTAssertTrue(toggled.isCollapsed)

        try await service.toggleCollapse(nodeID: node.id)
        let restored = try await nodeRepository.fetch(by: node.id)!
        XCTAssertFalse(restored.isCollapsed)
    }

    func test_indent_noopWhenNoPreviousSibling() async throws {
        let root = makeNode(depth: 0, sortIndex: 1000)
        try await nodeRepository.create(root)

        // 只有一个根节点，没有前一个同级节点，indent 应该无副作用
        try await service.indent(nodeID: root.id, in: pageID)

        let updated = try await nodeRepository.fetch(by: root.id)!
        XCTAssertNil(updated.parentNodeID, "没有前一个同级节点时 indent 不应改变父节点")
        XCTAssertEqual(updated.depth, 0)
    }

    // MARK: - Helpers

    private func makeNode(id: UUID = UUID(), depth: Int, sortIndex: Double, parentNodeID: UUID? = nil) -> Node {
        Node(
            id: id,
            pageID: pageID,
            parentNodeID: parentNodeID,
            title: "节点",
            depth: depth,
            sortIndex: sortIndex,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeBlock(nodeID: UUID) -> Block {
        Block(
            id: UUID(),
            nodeID: nodeID,
            type: .text,
            content: "内容",
            sortIndex: 1000,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
```

**Git commit message：**

```
test: add NodeMutationService unit tests
```

---

### M4-37～39：`Tests/UnitTests/BlockEditingServiceTests.swift`

对应 issue：`addBlock` / `deleteBlock` / `updateContent` 三个测试 issue

```swift
import XCTest
@testable import Notte

final class BlockEditingServiceTests: XCTestCase {

    var blockRepository: MockBlockRepository!
    var service: BlockEditingService!
    let nodeID = UUID()

    override func setUp() {
        blockRepository = MockBlockRepository()
        service = BlockEditingService(blockRepository: blockRepository)
    }

    func test_addBlock_createsBlockWithIncrementingSortIndex() async throws {
        let first = try await service.addBlock(nodeID: nodeID, type: .text)
        let second = try await service.addBlock(nodeID: nodeID, type: .text)
        XCTAssertGreaterThan(second.sortIndex, first.sortIndex)
    }

    func test_addBlock_assignsCorrectNodeID() async throws {
        let block = try await service.addBlock(nodeID: nodeID, type: .text)
        XCTAssertEqual(block.nodeID, nodeID)
    }

    func test_updateContent_persistsNewContent() async throws {
        let block = try await service.addBlock(nodeID: nodeID, type: .text)
        try await service.updateContent(blockID: block.id, content: "你好 Notte")
        let updated = try await blockRepository.fetch(by: block.id)!
        XCTAssertEqual(updated.content, "你好 Notte")
    }

    func test_deleteBlock_removesFromRepository() async throws {
        let block = try await service.addBlock(nodeID: nodeID, type: .text)
        try await service.deleteBlock(blockID: block.id)
        let result = try await blockRepository.fetch(by: block.id)
        XCTAssertNil(result)
    }

    func test_reorderBlock_updatesSortIndex() async throws {
        let block = try await service.addBlock(nodeID: nodeID, type: .text)
        try await service.reorderBlock(blockID: block.id, newSortIndex: 500)
        let updated = try await blockRepository.fetch(by: block.id)!
        XCTAssertEqual(updated.sortIndex, 500)
    }
}
```

**Git commit message：**

```
test: add BlockEditingService unit tests
```

---

### M4-40：`Tests/UnitTests/PageEditorViewModelLoadTests.swift`

对应 issue：`Add PageEditorViewModel load test`

```swift
import XCTest
@testable import Notte

final class PageEditorViewModelLoadTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var viewModel: PageEditorViewModel!
    let pageID = UUID()

    override func setUp() {
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        viewModel = PageEditorViewModel(
            pageID: pageID,
            pageTitle: "测试页面",
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
    }

    func test_loadPage_emptyPage_visibleNodesIsEmpty() async {
        await viewModel.loadPage()
        XCTAssertTrue(viewModel.visibleNodes.isEmpty)
    }

    func test_loadPage_withNodes_visibleNodesReflectsCount() async throws {
        let node1 = makeNode(depth: 0, sortIndex: 1000)
        let node2 = makeNode(depth: 0, sortIndex: 2000)
        try await nodeRepository.create(node1)
        try await nodeRepository.create(node2)

        await viewModel.loadPage()
        XCTAssertEqual(viewModel.visibleNodes.count, 2)
    }

    func test_loadPage_collapsedNode_hidesChildInVisibleNodes() async throws {
        let parentID = UUID()
        var parent = makeNode(id: parentID, depth: 0, sortIndex: 1000)
        parent.isCollapsed = true
        let child = makeNode(depth: 1, sortIndex: 1000, parentNodeID: parentID)
        try await nodeRepository.create(parent)
        try await nodeRepository.create(child)

        await viewModel.loadPage()
        XCTAssertEqual(viewModel.visibleNodes.count, 1, "折叠节点的子节点不应出现在 visibleNodes 中")
    }

    // MARK: - Helpers

    private func makeNode(id: UUID = UUID(), depth: Int, sortIndex: Double, parentNodeID: UUID? = nil) -> Node {
        Node(id: id, pageID: pageID, parentNodeID: parentNodeID,
             title: "节点", depth: depth, sortIndex: sortIndex,
             isCollapsed: false, createdAt: Date(), updatedAt: Date())
    }
}
```

**Git commit message：**

```
test: add PageEditorViewModel load tests
```

---

### M4-41：`Tests/UnitTests/NodeMutationServiceMoveTests.swift`

对应 issue：`Add NodeMutationService.moveUp/moveDown unit tests`（单独文件以保持清晰）

```swift
import XCTest
@testable import Notte

final class NodeMutationServiceMoveTests: XCTestCase {

    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var service: NodeMutationService!
    let pageID = UUID()

    override func setUp() {
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        service = NodeMutationService(
            nodeRepository: nodeRepository,
            blockRepository: blockRepository,
            queryService: NodeQueryService()
        )
    }

    func test_moveUp_swapsSortIndexWithPreviousSibling() async throws {
        let first = makeNode(depth: 0, sortIndex: 1000)
        let second = makeNode(depth: 0, sortIndex: 2000)
        try await nodeRepository.create(first)
        try await nodeRepository.create(second)

        try await service.moveUp(nodeID: second.id, in: pageID)

        let updatedSecond = try await nodeRepository.fetch(by: second.id)!
        let updatedFirst = try await nodeRepository.fetch(by: first.id)!
        XCTAssertLessThan(updatedSecond.sortIndex, updatedFirst.sortIndex, "移动后 second 应排在 first 之前")
    }

    func test_moveDown_swapsSortIndexWithNextSibling() async throws {
        let first = makeNode(depth: 0, sortIndex: 1000)
        let second = makeNode(depth: 0, sortIndex: 2000)
        try await nodeRepository.create(first)
        try await nodeRepository.create(second)

        try await service.moveDown(nodeID: first.id, in: pageID)

        let updatedFirst = try await nodeRepository.fetch(by: first.id)!
        let updatedSecond = try await nodeRepository.fetch(by: second.id)!
        XCTAssertGreaterThan(updatedFirst.sortIndex, updatedSecond.sortIndex, "移动后 first 应排在 second 之后")
    }

    func test_moveUp_noopWhenNoPreviousSibling() async throws {
        let only = makeNode(depth: 0, sortIndex: 1000)
        try await nodeRepository.create(only)
        let originalIndex = only.sortIndex

        try await service.moveUp(nodeID: only.id, in: pageID)

        let updated = try await nodeRepository.fetch(by: only.id)!
        XCTAssertEqual(updated.sortIndex, originalIndex, "无前一个节点时 moveUp 不应改变 sortIndex")
    }

    private func makeNode(id: UUID = UUID(), depth: Int, sortIndex: Double) -> Node {
        Node(id: id, pageID: pageID, parentNodeID: nil,
             title: "节点", depth: depth, sortIndex: sortIndex,
             isCollapsed: false, createdAt: Date(), updatedAt: Date())
    }
}
```

**Git commit message：**

```
test: add NodeMutationService moveUp/moveDown unit tests
```

---

### M4-42：端到端测试（创建 → 持久化 → 重启 → 验证）

对应 issue：`Add end-to-end: create node → persist → relaunch → verify`  
**文件：** `Tests/IntegrationTests/NodePersistenceIntegrationTests.swift`

```swift
import XCTest
import SwiftData
@testable import Notte

/// 端到端集成测试：使用真实内存 SwiftData 容器验证 Node 从创建到持久化的完整链路。
final class NodePersistenceIntegrationTests: XCTestCase {

    var container: ModelContainer!
    var nodeRepository: NodeRepository!
    var blockRepository: BlockRepository!
    let pageID = UUID()

    override func setUpWithError() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        nodeRepository = NodeRepository(context: context)
        blockRepository = BlockRepository(context: context)
    }

    func test_createNode_persistsAndReloadsCorrectly() async throws {
        // 1. 创建节点
        let node = Node(
            id: UUID(), pageID: pageID, parentNodeID: nil,
            title: "持久化测试节点", depth: 0, sortIndex: 1000,
            isCollapsed: false, createdAt: Date(), updatedAt: Date()
        )
        try await nodeRepository.create(node)

        // 2. 创建关联 Block
        let block = Block(
            id: UUID(), nodeID: node.id, type: .text,
            content: "端到端内容", sortIndex: 1000, createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(block)

        // 3. 重新查询（模拟重启后重新加载）
        let loadedNodes = try await nodeRepository.fetchAll(in: pageID)
        let loadedBlocks = try await blockRepository.fetchAll(in: node.id)

        XCTAssertEqual(loadedNodes.count, 1)
        XCTAssertEqual(loadedNodes.first?.title, "持久化测试节点")
        XCTAssertEqual(loadedBlocks.count, 1)
        XCTAssertEqual(loadedBlocks.first?.content, "端到端内容")
    }

    func test_deleteNode_alsoRemovesBlocks() async throws {
        let nodeID = UUID()
        let node = Node(
            id: nodeID, pageID: pageID, parentNodeID: nil,
            title: "待删节点", depth: 0, sortIndex: 1000,
            isCollapsed: false, createdAt: Date(), updatedAt: Date()
        )
        try await nodeRepository.create(node)
        let block = Block(
            id: UUID(), nodeID: nodeID, type: .text,
            content: "待删内容", sortIndex: 1000, createdAt: Date(), updatedAt: Date()
        )
        try await blockRepository.create(block)

        // 执行级联删除
        try await blockRepository.deleteAll(in: nodeID)
        try await nodeRepository.delete(by: nodeID)

        let nodes = try await nodeRepository.fetchAll(in: pageID)
        let blocks = try await blockRepository.fetchAll(in: nodeID)
        XCTAssertTrue(nodes.isEmpty)
        XCTAssertTrue(blocks.isEmpty)
    }
}
```

**Git commit message：**

```
test: add end-to-end node persistence integration test
```

**解释（测试整体）：**

- M4-27／28（Mock）→ M4-29／30（QueryService）→ M4-31～36（MutationService）→ M4-37～39（BlockEditingService）→ M4-40（ViewModel load）→ M4-41（moveUp/moveDown）→ M4-42（端到端）：测试 issue 按层次从内到外逐层覆盖。
- M4-42 是唯一使用真实 SwiftData 容器（内存模式）的测试，放在 `Tests/IntegrationTests/` 而非 `UnitTests/`，明确区分单元测试与集成测试。
- `PersistenceController.makeContainer(inMemory: true)` 是 M1 阶段已实现的接口，这里直接复用，每次测试使用全新的内存容器，互不干扰。

---

## 目录结构速览

M4 新增与修改的文件一览：

```
Notte/
├── App/
│   ├── AppRouter.swift                                ← 更新：AppRoute.nodeEditor 新增 pageTitle
│   ├── RootView.swift                                 ← 更新：替换 .nodeEditor 占位为 PageEditorView
│   └── DependencyContainer.swift                      ← 更新：新增 nodeRepository、blockRepository
│
├── Features/
│   ├── Pages/
│   │   └── UseCases/
│   │       └── DeletePageUseCase.swift                ← 更新：补全 Block 级联删除
│   │
│   └── NodeEditor/                                    ← 新增整个模块
│       ├── Engine/
│       │   ├── EditorNode.swift
│       │   ├── EditorBlock.swift
│       │   └── NodeEditorEngine.swift
│       ├── Commands/
│       │   ├── NodeCommand.swift
│       │   └── BlockCommand.swift
│       ├── Services/
│       │   ├── NodeQueryService.swift
│       │   ├── NodeMutationService.swift
│       │   ├── BlockEditingService.swift
│       │   └── NodePersistenceCoordinator.swift
│       ├── ViewModels/
│       │   └── PageEditorViewModel.swift
│       └── Views/
│           ├── PageEditorView.swift
│           ├── NodeRowView.swift
│           ├── NodeContentEditor.swift
│           ├── NodeIndentationGuide.swift
│           ├── NodeCollapseControl.swift
│           ├── NodeTypeIndicator.swift
│           └── AddNodeButton.swift                    ← 新增
│
├── Domain/
│   └── Protocols/
│       ├── NodeRepositoryProtocol.swift               ← 更新：方法签名改为 async throws
│       └── BlockRepositoryProtocol.swift              ← 更新：方法签名改为 async throws
│
└── Data/
    └── Repositories/
        ├── NodeRepository.swift                       ← 更新：骨架 → 完整实现，async throws
        └── BlockRepository.swift                      ← 更新：骨架 → 完整实现，async throws

Tests/
├── UnitTests/
│   ├── NodeQueryServiceTests.swift                    ← M4-29/30（buildTree + visibleNodes）
│   ├── NodeMutationServiceTests.swift                 ← M4-31～34/36（insert/indent/outdent/delete/collapse）
│   ├── NodeMutationServiceMoveTests.swift             ← M4-35（moveUp/moveDown）
│   ├── BlockEditingServiceTests.swift                 ← M4-37～39（add/delete/updateContent）
│   ├── PageEditorViewModelLoadTests.swift             ← M4-40（ViewModel load）
│   └── Mocks/
│       ├── MockNodeRepository.swift                   ← M4-27
│       └── MockBlockRepository.swift                  ← M4-28
└── IntegrationTests/
    └── NodePersistenceIntegrationTests.swift          ← M4-42（端到端）
```

---

> M4 Node Editor Core 全部完成。验收条件：打开 Page 后能看到 Node 列表；增删节点正确；缩进/反缩进准确更新 depth 和 parentNodeID；折叠后子节点不出现在列表；Block 内容可编辑；退出页面重新进入后所有数据完整保留；单元测试全部通过。
