# Notte M6 代码参考文档

> 本文档包含 M6（Onboarding & Settings）阶段所有 issue 的文件路径、代码内容与解释。
> M6 目标：新用户首次打开不迷失，3 分钟内理解 `Collection → Page → Node → Block` 模型；提供示例数据一键导入；上线极简设置页。

---

## 分支

```
feature/onboarding-settings
```

## 目录

1. [M6-01 OnboardingView 屏 1：产品理念与层级示意](#m6-01-onboardingview-屏-1产品理念与层级示意)
2. [M6-02 OnboardingView 屏 2：核心模型说明](#m6-02-onboardingview-屏-2核心模型说明)
3. [M6-03 OnboardingView 屏 3：开始使用 CTA](#m6-03-onboardingview-屏-3开始使用-cta)
4. [M6-04 跳过引导动作](#m6-04-跳过引导动作)
5. [M6-05 "创建第一个 Collection" CTA](#m6-05-创建第一个-collection-cta)
6. [M6-06 "导入示例数据" CTA](#m6-06-导入示例数据-cta)
7. [M6-07 首次运行检测（AppStorage）](#m6-07-首次运行检测appstorage)
8. [M6-08 ExampleDataFactory 协议与实现](#m6-08-exampledatafactory-协议与实现)
9. [M6-09 SwiftUI 学习示例 JSON](#m6-09-swiftui-学习示例-json)
10. [M6-10 项目规划示例 JSON](#m6-10-项目规划示例-json)
11. [M6-11 读书笔记示例 JSON](#m6-11-读书笔记示例-json)
12. [M6-12 SettingsView 主屏](#m6-12-settingsview-主屏)
13. [M6-13 iCloud 同步状态分区（M7 占位）](#m6-13-icloud-同步状态分区m7-占位)
14. [M6-14 外观分区](#m6-14-外观分区)
15. [M6-15 关于分区](#m6-15-关于分区)
16. [M6-16 调试分区（DEBUG）](#m6-16-调试分区debug)
17. [M6-17 Onboarding 完成标记持久化测试](#m6-17-onboarding-完成标记持久化测试)
18. [M6-18 示例数据导入完整性测试](#m6-18-示例数据导入完整性测试)
19. [M6-19 Onboarding 页面导航 UI 测试](#m6-19-onboarding-页面导航-ui-测试)
20. [M6-20 SettingsView 渲染测试](#m6-20-settingsview-渲染测试)

---

## M6-01 OnboardingView 屏 1：产品理念与层级示意

**文件：** `Features/Onboarding/Views/OnboardingScreenOne.swift` / `Features/Onboarding/Components/OnboardingHierarchyIllustration.swift` / `Features/Onboarding/ViewModels/OnboardingViewModel.swift`

```swift
// Features/Onboarding/ViewModels/OnboardingViewModel.swift
import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    let totalPages: Int = 3

    func next() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }

    func previous() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }
}
```

```swift
// Features/Onboarding/Components/OnboardingHierarchyIllustration.swift
import SwiftUI

/// 静态层级示意图：Collection → Page → Node → Block。
/// 用 SwiftUI 原生组件绘制，不依赖外部素材，深浅色自动适配。
struct OnboardingHierarchyIllustration: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            tier(icon: "tray.full", title: "Collection", indent: 0)
            tier(icon: "doc.text", title: "Page", indent: 1)
            tier(icon: "list.bullet.indent", title: "Node", indent: 2)
            tier(icon: "text.alignleft", title: "Block", indent: 3)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tier(icon: String, title: String, indent: Int) -> some View {
        HStack(spacing: SpacingTokens.sm) {
            ForEach(0..<indent, id: \.self) { _ in
                Rectangle()
                    .fill(ColorTokens.separator.opacity(0.4))
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, SpacingTokens.xs)
            }
            Image(systemName: icon)
                .foregroundStyle(ColorTokens.accent)
            Text(title)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textPrimary)
        }
    }
}
```

```swift
// Features/Onboarding/Views/OnboardingScreenOne.swift
import SwiftUI

struct OnboardingScreenOne: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Text("结构化地记录一切")
                .font(TypographyTokens.largeTitle)
                .foregroundStyle(ColorTokens.textPrimary)
            Text("Notte 帮助你快速记录，自然形成结构，长期积累知识。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingTokens.lg)
            OnboardingHierarchyIllustration()
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
    }
}
```

**Git commit message：**

```
feat: add onboarding view model and screen one
```

**解释：**

- `OnboardingViewModel` 只持有 `currentPage`，导航通过 `next/previous` 推进，不暴露内部状态机给 View。
- 层级示意图用 SF Symbols + `Rectangle()` 模拟缩进线，保持与 NodeEditor 的视觉语言一致（同样使用 `separator.opacity(0.4)` 竖线）。
- 屏内排版统一使用 `SpacingTokens`，不出现魔法数。

---

## M6-02 OnboardingView 屏 2：核心模型说明

**文件：** `Features/Onboarding/Views/OnboardingScreenTwo.swift`

```swift
import SwiftUI

struct OnboardingScreenTwo: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Text("三个对象，一套系统")
                .font(TypographyTokens.largeTitle)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(alignment: .leading, spacing: SpacingTokens.md) {
                conceptRow(
                    icon: "tray.full",
                    title: "Collection",
                    subtitle: "专题空间，按主题组织所有内容"
                )
                conceptRow(
                    icon: "doc.text",
                    title: "Page",
                    subtitle: "一篇完整的笔记或文档"
                )
                conceptRow(
                    icon: "list.bullet.indent",
                    title: "Node",
                    subtitle: "可自由移动、重组的内容模块"
                )
            }
            .padding(SpacingTokens.lg)
            .background(ColorTokens.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
    }

    private func conceptRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: SpacingTokens.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ColorTokens.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                Text(title)
                    .font(TypographyTokens.title)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(subtitle)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }
}
```

**Git commit message：**

```
feat: add onboarding screen two
```

**解释：**

- 屏 2 是产品概念的"字典"，把三个对象的语义对齐到用户已有的心智（专题空间 / 笔记 / 模块）。
- Block 在 MVP 阶段只有 text 一种类型，因此 onboarding 不单独把 Block 拿出来讲——避免用户预期与现实不符。M6-01 的层级图保留 Block，是为了承诺"它在那里"。

---

## M6-03 OnboardingView 屏 3：开始使用 CTA

**文件：** `Features/Onboarding/Views/OnboardingScreenThree.swift` / `Features/Onboarding/Views/OnboardingView.swift`

```swift
// Features/Onboarding/Views/OnboardingScreenThree.swift
import SwiftUI

struct OnboardingScreenThree: View {
    let onCreateFirstCollection: () -> Void
    let onImportSampleData: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()
            Text("准备好了吗？")
                .font(TypographyTokens.largeTitle)
                .foregroundStyle(ColorTokens.textPrimary)
            Text("选择一种方式开始")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(spacing: SpacingTokens.sm) {
                Button(action: onCreateFirstCollection) {
                    Text("创建我的第一个 Collection")
                        .font(TypographyTokens.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SpacingTokens.md)
                        .background(ColorTokens.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(action: onImportSampleData) {
                    Text("导入示例数据")
                        .font(TypographyTokens.body)
                        .foregroundStyle(ColorTokens.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SpacingTokens.md)
                        .background(ColorTokens.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, SpacingTokens.md)
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
    }
}
```

```swift
// Features/Onboarding/Views/OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    let onCreateFirstCollection: () -> Void
    let onImportSampleData: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("跳过") {
                    hasCompletedOnboarding = true
                }
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(SpacingTokens.md)
            }

            TabView(selection: $viewModel.currentPage) {
                OnboardingScreenOne()
                    .tag(0)
                OnboardingScreenTwo()
                    .tag(1)
                OnboardingScreenThree(
                    onCreateFirstCollection: {
                        hasCompletedOnboarding = true
                        onCreateFirstCollection()
                    },
                    onImportSampleData: {
                        hasCompletedOnboarding = true
                        onImportSampleData()
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(ColorTokens.backgroundPrimary)
    }
}
```

**Git commit message：**

```
feat: assemble onboarding view with paging and CTAs
```

**解释：**

- `TabView` + `.page` 提供原生左右滑动、分页指示器，不重复造轮子。
- CTA 闭包由外部注入（`onCreateFirstCollection` / `onImportSampleData`），Onboarding 模块不直接持有 Repository，符合"Features 不直接依赖 Data"的分层约束。
- 两个 CTA 在触发前都把 `hasCompletedOnboarding` 写为 `true`，避免用户点完进入主页后又被引导拦截。

---

## M6-04 跳过引导动作

**文件：** `Features/Onboarding/Views/OnboardingView.swift`（顶部"跳过"按钮）

```swift
Button("跳过") {
    hasCompletedOnboarding = true
}
```

**Git commit message：**

```
feat: support skipping onboarding
```

**解释：**

- "跳过"只翻转标记，不调用 CTA。用户进入空主页，由 `CollectionEmptyState` 引导创建。
- 不弹二次确认：onboarding 是可重复学习的资料，跳过的成本极低；在 SettingsView 的调试分区可以重置标记重新查看（DEBUG 构建）。

---

## M6-05 "创建第一个 Collection" CTA

**文件：** `App/RootView.swift`（注入回调） / `Features/Collections/ViewModels/CollectionListViewModel.swift`（暴露弹窗触发）

```swift
// App/RootView.swift（核心改动）
struct RootView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var pendingAction: PostOnboardingAction?

    enum PostOnboardingAction { case createFirst, importSamples }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(
                    onCreateFirstCollection: { pendingAction = .createFirst },
                    onImportSampleData: { pendingAction = .importSamples }
                )
            } else {
                mainNavigation
            }
        }
    }

    private var mainNavigation: some View {
        NavigationStack(path: $router.path) {
            CollectionListScreen(
                repository: dependencyContainer.collectionRepository,
                pageRepository: dependencyContainer.pageRepository,
                nodeRepository: dependencyContainer.nodeRepository,
                pendingAction: pendingAction,
                onActionConsumed: { pendingAction = nil }
            )
            // ... 既有 navigationDestination
        }
        .environmentObject(router)
    }
}
```

```swift
// Features/Collections/ViewModels/CollectionListViewModel.swift（新增）
func handlePendingCreateFirst() {
    isShowingCreateSheet = true
}
```

```swift
// Features/Collections/Views/CollectionListScreen.swift（新增触发）
.task {
    await viewModel.loadCollections()
    if pendingAction == .createFirst {
        viewModel.handlePendingCreateFirst()
        onActionConsumed()
    }
}
```

**Git commit message：**

```
feat: route create-first CTA from onboarding to collection sheet
```

**解释：**

- Onboarding 完成时不直接调用 Repository，而是把意图（`PostOnboardingAction`）放在 RootView 的 State 里，由 `CollectionListScreen` 在加载完成后消费一次后清空。这样保证：
  1. CTA 触发 → 标记完成 → 切换到主导航 → 列表加载 → 弹出创建 Sheet，整条链路在 SwiftUI 视图刷新内完成；
  2. 用户后续返回首页不会再次弹窗（`onActionConsumed` 在执行后清空）。

---

## M6-06 "导入示例数据" CTA

**文件：** `App/RootView.swift`（消费 `.importSamples`） / `Features/Collections/ViewModels/CollectionListViewModel.swift`（新增导入入口）

```swift
// Features/Collections/ViewModels/CollectionListViewModel.swift（新增方法）
func importSampleData(using factory: ExampleDataFactory) async {
    isLoading = true
    defer { isLoading = false }
    do {
        try await factory.importAll()
        await loadCollections()
    } catch {
        self.error = AppError.unknown(error.localizedDescription)
    }
}
```

```swift
// Features/Collections/Views/CollectionListScreen.swift（新增触发）
.task {
    await viewModel.loadCollections()
    switch pendingAction {
    case .createFirst:
        viewModel.handlePendingCreateFirst()
    case .importSamples:
        await viewModel.importSampleData(using: dependencyContainer.makeExampleDataFactory())
    case nil:
        break
    }
    onActionConsumed()
}
```

**Git commit message：**

```
feat: wire import sample data CTA to collection list
```

**解释：**

- 示例数据导入是一次性原子操作，用 `defer` 守护 `isLoading` 复位。
- 导入失败时统一走 `AppError`，复用 `CollectionListScreen` 既有的错误 Alert，不为示例导入再造一个错误展示路径。
- `dependencyContainer.makeExampleDataFactory()` 工厂方法在 M6-08 添加；通过 DI 容器构造工厂，保持 ViewModel 不直接依赖 Repository。

---

## M6-07 首次运行检测（AppStorage）

**文件：** `App/RootView.swift`（已在 M6-05 引入） / `App/AppBootStrap.swift`（无需改动）

```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
```

**Git commit message：**

```
feat: detect first run with AppStorage flag
```

**解释：**

- 用 `@AppStorage` 而非自建 UserDefaults 包装：键名"hasCompletedOnboarding"是 MVP 范围内唯一的引导持久化字段，没必要预先抽象。
- 标记反转时机：CTA / 跳过都会写入，不依赖屏 3 的"开始使用"按钮——任何提前结束的路径都被覆盖。
- 重置入口：DEBUG 构建的调试菜单（M6-16）提供"重新查看引导"按钮，避免开发期反复擦库。

---

## M6-08 ExampleDataFactory 协议与实现

**文件：** `Features/Onboarding/Services/ExampleDataFactory.swift` / `App/DependencyContainer.swift`

```swift
// Features/Onboarding/Services/ExampleDataFactory.swift
import Foundation

/// JSON Schema：
/// {
///   "title": "Collection 标题",
///   "iconName": "tray.full",
///   "colorToken": null,
///   "pages": [
///     {
///       "title": "Page 标题",
///       "nodes": [
///         {
///           "title": "Node 标题",
///           "depth": 0,
///           "children": [ /* 递归 Node */ ],
///           "blocks": [
///             { "type": "text", "content": "Block 内容" }
///           ]
///         }
///       ]
///     }
///   ]
/// }
struct ExampleDataFactory {
    let collectionRepository: CollectionRepositoryProtocol
    let pageRepository: PageRepositoryProtocol
    let nodeRepository: NodeRepositoryProtocol
    let blockRepository: BlockRepositoryProtocol

    private let sampleFiles = ["SwiftUILearning", "ProjectPlanning", "ReadingNotes"]
    private let logger = ConsoleLogger()

    func importAll() async throws {
        for file in sampleFiles {
            try await importOne(file: file)
        }
    }

    func importOne(file: String) async throws {
        guard let url = Bundle.main.url(forResource: file, withExtension: "json", subdirectory: "SampleData")
            ?? Bundle.main.url(forResource: file, withExtension: "json") else {
            throw RepositoryError.notFound
        }
        let data = try Data(contentsOf: url)
        let dto = try JSONDecoder().decode(SampleCollectionDTO.self, from: data)
        try await persist(dto: dto)
        logger.info("示例数据导入完成: \(file)", function: #function)
    }

    private func persist(dto: SampleCollectionDTO) async throws {
        let existing = try await collectionRepository.fetchAll()
        let baseSortIndex = (existing.map(\.sortIndex).max() ?? 0) + 1000

        let collection = Collection(
            id: UUID(),
            title: dto.title,
            iconName: dto.iconName,
            colorToken: dto.colorToken,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: baseSortIndex,
            isPinned: false
        )
        try await collectionRepository.create(collection)

        for (pageIdx, pageDTO) in dto.pages.enumerated() {
            let page = Page(
                id: UUID(),
                collectionID: collection.id,
                title: pageDTO.title,
                createdAt: Date(),
                updatedAt: Date(),
                sortIndex: Double(pageIdx + 1) * 1000,
                isArchived: false
            )
            try await pageRepository.create(page)

            try await persistNodes(pageDTO.nodes, pageID: page.id, parentNodeID: nil)
        }
    }

    private func persistNodes(
        _ dtos: [SampleNodeDTO],
        pageID: UUID,
        parentNodeID: UUID?
    ) async throws {
        for (idx, dto) in dtos.enumerated() {
            let node = Node(
                id: UUID(),
                pageID: pageID,
                parentNodeID: parentNodeID,
                title: dto.title,
                depth: dto.depth,
                sortIndex: Double(idx + 1) * 1000,
                isCollapsed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await nodeRepository.create(node)

            for (blockIdx, blockDTO) in (dto.blocks ?? []).enumerated() {
                let block = Block(
                    id: UUID(),
                    nodeID: node.id,
                    type: BlockType(rawValue: blockDTO.type) ?? .text,
                    content: blockDTO.content,
                    sortIndex: Double(blockIdx + 1) * 1000,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try await blockRepository.create(block)
            }

            try await persistNodes(dto.children ?? [], pageID: pageID, parentNodeID: node.id)
        }
    }
}

// MARK: - DTO

private struct SampleCollectionDTO: Decodable {
    let title: String
    let iconName: String?
    let colorToken: String?
    let pages: [SamplePageDTO]
}

private struct SamplePageDTO: Decodable {
    let title: String
    let nodes: [SampleNodeDTO]
}

private struct SampleNodeDTO: Decodable {
    let title: String
    let depth: Int
    let children: [SampleNodeDTO]?
    let blocks: [SampleBlockDTO]?
}

private struct SampleBlockDTO: Decodable {
    let type: String
    let content: String
}
```

```swift
// App/DependencyContainer.swift（新增工厂方法）
func makeExampleDataFactory() -> ExampleDataFactory {
    ExampleDataFactory(
        collectionRepository: collectionRepository,
        pageRepository: pageRepository,
        nodeRepository: nodeRepository,
        blockRepository: blockRepository
    )
}
```

**Git commit message：**

```
feat: add ExampleDataFactory for sample data import
```

**解释：**

- 工厂只读取 JSON，不内嵌任何示例字面量；每条示例与代码解耦，更新示例不需要重新编译。
- 递归处理 Node：`persistNodes` 接受 `parentNodeID`，深度由 JSON 显式给出，与运行时计算保持一致；`sortIndex` 在同级内按数组顺序生成（间隔 1000，符合 MVP `sortIndex` 策略）。
- 失败时抛 `RepositoryError`，错误展示由 ViewModel 转 `AppError`（M6-06）。
- 通过 DependencyContainer 提供工厂方法而不是直接持有实例：工厂在导入时才构造，避免长期占用容器内存。

---

## M6-09 SwiftUI 学习示例 JSON

**文件：** `Resources/SampleData/SwiftUILearning.json`

```json
{
  "title": "SwiftUI 学习",
  "iconName": "swift",
  "colorToken": null,
  "pages": [
    {
      "title": "SwiftUI 基础",
      "nodes": [
        {
          "title": "什么是 SwiftUI",
          "depth": 0,
          "blocks": [
            { "type": "text", "content": "Apple 推出的声明式 UI 框架，跨 iOS / iPadOS / macOS / watchOS / tvOS。" }
          ],
          "children": [
            { "title": "声明式语法", "depth": 1, "blocks": [{ "type": "text", "content": "用 body 描述视图应该长什么样，而不是怎么变化。" }] },
            { "title": "View 协议", "depth": 1, "blocks": [{ "type": "text", "content": "所有 View 都遵守 View 协议，必须提供 body。" }] }
          ]
        },
        {
          "title": "状态管理",
          "depth": 0,
          "children": [
            { "title": "@State", "depth": 1, "blocks": [{ "type": "text", "content": "用于值类型的局部状态。" }] },
            { "title": "@Binding", "depth": 1, "blocks": [{ "type": "text", "content": "双向绑定父视图传入的状态。" }] },
            { "title": "@StateObject / @ObservedObject", "depth": 1, "blocks": [{ "type": "text", "content": "用于引用类型的可观察对象。" }] }
          ]
        }
      ]
    },
    {
      "title": "布局系统",
      "nodes": [
        {
          "title": "HStack / VStack / ZStack",
          "depth": 0,
          "blocks": [{ "type": "text", "content": "三种基础容器，决定子视图的排列方向。" }]
        },
        {
          "title": "Spacer 与 Divider",
          "depth": 0,
          "blocks": [{ "type": "text", "content": "Spacer 填充剩余空间，Divider 在容器内自动绘制分隔线。" }]
        },
        {
          "title": "frame 与 padding",
          "depth": 0,
          "blocks": [{ "type": "text", "content": "frame 设置尺寸约束，padding 添加内边距。" }]
        }
      ]
    },
    {
      "title": "数据流",
      "nodes": [
        {
          "title": "Environment 对象",
          "depth": 0,
          "blocks": [{ "type": "text", "content": "用于跨层级注入共享对象，避免参数透传。" }]
        },
        {
          "title": "SwiftData 集成",
          "depth": 0,
          "blocks": [{ "type": "text", "content": "iOS 17+ 提供，与 SwiftUI 深度整合。" }]
        }
      ]
    }
  ]
}
```

**Git commit message：**

```
chore: add SwiftUI learning sample data
```

**解释：**

- 3 个 Page、12+ 个 Node，覆盖 2 层嵌套，体现 Node 的层级感。
- 每个叶子 Node 配一个 text Block，让用户进入编辑器就能看到完整的"标题 + 内容"组合。

---

## M6-10 项目规划示例 JSON

**文件：** `Resources/SampleData/ProjectPlanning.json`

```json
{
  "title": "项目规划",
  "iconName": "list.clipboard",
  "colorToken": null,
  "pages": [
    {
      "title": "需求梳理",
      "nodes": [
        { "title": "用户故事", "depth": 0, "blocks": [{ "type": "text", "content": "作为 …，我希望 …，以便 …。" }] },
        { "title": "竞品调研", "depth": 0, "blocks": [{ "type": "text", "content": "列出 3-5 个主要竞品的差异点。" }] },
        { "title": "MVP 范围", "depth": 0, "blocks": [{ "type": "text", "content": "明确 in-scope / out-of-scope。" }] }
      ]
    },
    {
      "title": "里程碑",
      "nodes": [
        {
          "title": "Milestone 1",
          "depth": 0,
          "children": [
            { "title": "工程底座", "depth": 1, "blocks": [{ "type": "text", "content": "工程可运行、数据模型就位。" }] },
            { "title": "首屏可见", "depth": 1, "blocks": [{ "type": "text", "content": "Collection 列表与空状态。" }] }
          ]
        },
        {
          "title": "Milestone 2",
          "depth": 0,
          "children": [
            { "title": "Editor 核心", "depth": 1, "blocks": [{ "type": "text", "content": "增删改、缩进、折叠全部成立。" }] }
          ]
        }
      ]
    },
    {
      "title": "风险与对策",
      "nodes": [
        { "title": "技术风险", "depth": 0, "blocks": [{ "type": "text", "content": "CloudKit 同步在阶段 7 才接入，确保模型字段提前稳定。" }] },
        { "title": "进度风险", "depth": 0, "blocks": [{ "type": "text", "content": "Editor 阶段如延期，优先砍 UX polish。" }] }
      ]
    }
  ]
}
```

**Git commit message：**

```
chore: add project planning sample data
```

**解释：**

- 含一个 2 层嵌套的 Milestone 结构，展示 Node 适合做"待办大纲"的能力。
- 三个 Page 覆盖典型项目流程：需求 → 里程碑 → 风险。

---

## M6-11 读书笔记示例 JSON

**文件：** `Resources/SampleData/ReadingNotes.json`

```json
{
  "title": "读书笔记",
  "iconName": "book",
  "colorToken": null,
  "pages": [
    {
      "title": "《思考，快与慢》",
      "nodes": [
        { "title": "系统 1 与系统 2", "depth": 0, "blocks": [{ "type": "text", "content": "直觉系统快但易错，理性系统慢但准确。" }] },
        {
          "title": "认知偏差",
          "depth": 0,
          "children": [
            { "title": "锚定效应", "depth": 1, "blocks": [{ "type": "text", "content": "初始数值会影响后续判断。" }] },
            { "title": "可得性启发", "depth": 1, "blocks": [{ "type": "text", "content": "越容易回忆的事件被判断为越常见。" }] }
          ]
        },
        { "title": "前景理论", "depth": 0, "blocks": [{ "type": "text", "content": "损失带来的痛苦大于同等收益的快乐。" }] }
      ]
    },
    {
      "title": "《原则》",
      "nodes": [
        { "title": "极度求真", "depth": 0, "blocks": [{ "type": "text", "content": "面对现实，不自我欺骗。" }] },
        { "title": "可信度加权", "depth": 0, "blocks": [{ "type": "text", "content": "决策时按可信度权重综合不同意见。" }] },
        { "title": "五步流程", "depth": 0, "blocks": [{ "type": "text", "content": "目标 → 问题 → 诊断 → 设计 → 执行。" }] }
      ]
    }
  ]
}
```

**Git commit message：**

```
chore: add reading notes sample data
```

**解释：**

- 2 个 Page，包含 8+ Node，至少一层嵌套（认知偏差）。
- 内容贴近"个人知识库"使用场景，让用户立刻感知到 Notte 适合做长期积累。

---

## M6-12 SettingsView 主屏

**文件：** `Features/Settings/Views/SettingsView.swift` / `Features/Settings/ViewModels/SettingsViewModel.swift`

```swift
// Features/Settings/ViewModels/SettingsViewModel.swift
import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }()
}
```

```swift
// Features/Settings/Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                SettingsSyncSection()
                SettingsAppearanceSection()
                SettingsAboutSection(version: viewModel.appVersion)
                #if DEBUG
                SettingsDebugSection()
                #endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .background(ColorTokens.backgroundPrimary)
        }
    }
}
```

**Git commit message：**

```
feat: add settings view scaffold
```

**解释：**

- 主屏只装配分区，不持有具体逻辑；各分区独立为 View，便于单独渲染和测试。
- `SettingsViewModel` 只暴露版本号；其余分区是无状态视图（同步状态在 M7 才有真状态）。
- 调试分区通过 `#if DEBUG` 编译期裁剪，Release 包不携带任何调试入口。

---

## M6-13 iCloud 同步状态分区（M7 占位）

**文件：** `Features/Settings/Views/SettingsSyncSection.swift`

```swift
import SwiftUI

struct SettingsSyncSection: View {
    var body: some View {
        Section("iCloud 同步") {
            HStack {
                Image(systemName: "icloud")
                    .foregroundStyle(ColorTokens.textSecondary)
                Text("未开启")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Text("即将推出")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Text("启用后，你的 Collection、Page、Node 将自动同步到你的所有 Apple 设备。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }
}
```

**Git commit message：**

```
feat: add iCloud sync placeholder section
```

**解释：**

- M6 阶段只提供"占位"：状态与开关都不接 Repository。
- 文案明确告知"即将推出"，避免用户误以为已支持但配置失败。
- M7 接入时只需替换 Body 内的状态读取，不动 SettingsView 主屏。

---

## M6-14 外观分区

**文件：** `Features/Settings/Views/SettingsAppearanceSection.swift`

```swift
import SwiftUI

struct SettingsAppearanceSection: View {
    var body: some View {
        Section("外观") {
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(ColorTokens.textSecondary)
                Text("跟随系统")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            Text("Notte 会自动适配你在系统设置中选择的浅色或深色模式。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }
}
```

**Git commit message：**

```
feat: add appearance section
```

**解释：**

- MVP 不提供手动主题切换：颜色 Token 已经覆盖深浅色，强制跟随系统降低维护面。
- 仅作"说明性"分区，让用户知道为什么没有切换开关。

---

## M6-15 关于分区

**文件：** `Features/Settings/Views/SettingsAboutSection.swift`

```swift
import SwiftUI

struct SettingsAboutSection: View {
    let version: String

    private let feedbackURL = URL(string: "mailto:feedback@notte.app")!
    private let privacyURL = URL(string: "https://notte.app/privacy")!

    var body: some View {
        Section("关于 Notte") {
            HStack {
                Text("版本")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Text(version)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Link(destination: feedbackURL) {
                Label("反馈与建议", systemImage: "envelope")
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            Link(destination: privacyURL) {
                Label("隐私政策", systemImage: "hand.raised")
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
    }
}
```

**Git commit message：**

```
feat: add about section with version feedback and privacy
```

**解释：**

- 版本号从 `Bundle.main` 读取，不硬编码字符串。
- 反馈用 `mailto:` 链接，无需自建表单；MVP 阶段邮件即可。
- 隐私政策链接占位，发布前需替换为正式域名。

---

## M6-16 调试分区（DEBUG）

**文件：** `Features/Settings/Views/SettingsDebugSection.swift`

```swift
import SwiftUI
import SwiftData

#if DEBUG
struct SettingsDebugSection: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isImporting: Bool = false

    var body: some View {
        Section("调试") {
            Button {
                isImporting = true
                Task {
                    try? await dependencyContainer.makeExampleDataFactory().importAll()
                    isImporting = false
                }
            } label: {
                Label(isImporting ? "导入中..." : "填充示例数据", systemImage: "tray.and.arrow.down")
            }
            .disabled(isImporting)

            Button(role: .destructive) {
                clearAllData()
            } label: {
                Label("清空所有数据", systemImage: "trash")
            }

            Button {
                hasCompletedOnboarding = false
            } label: {
                Label("重新查看引导", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private func clearAllData() {
        try? modelContext.delete(model: CollectionModel.self)
        try? modelContext.delete(model: PageModel.self)
        try? modelContext.delete(model: NodeModel.self)
        try? modelContext.delete(model: BlockModel.self)
        try? modelContext.save()
    }
}
#endif
```

**Git commit message：**

```
feat: add debug section with sample import clear and onboarding reset
```

**解释：**

- 复用 `ExampleDataFactory`，避免在调试入口里重写一份导入逻辑。
- "清空所有数据"按模型类型批量删除，触发 SwiftData 的级联清理。
- "重新查看引导" 把 `hasCompletedOnboarding` 翻回 `false`，开发期反复验证 onboarding 流程不需要重装 App。
- 既有 `Infrastructure/Debug/DebugMenuView` 中 `clearAllData` 的占位实现（注释 "M6 示例数据功能完成后填充"）也在本 issue 一并补全。

**附加 commit message：**

```
chore: implement debug menu clear action
```

---

## M6-17 Onboarding 完成标记持久化测试

**文件：** `NotteTests/UnitTests/OnboardingPersistenceTests.swift`

```swift
import XCTest
@testable import Notte

@MainActor
final class OnboardingPersistenceTests: XCTestCase {

    private let key = "hasCompletedOnboarding"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    /// 测试：默认值为 false，首次启动需要展示引导
    func testDefaultIsFalse() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: key))
    }

    /// 测试：写入 true 后跨实例读取保持为 true
    func testFlagPersistsAcrossReads() {
        UserDefaults.standard.set(true, forKey: key)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key))
    }
}
```

**Git commit message：**

```
test: cover onboarding completion flag persistence
```

**解释：**

- 直接测 `UserDefaults` 行为，而不是测 `@AppStorage` 包装——后者只是属性包装器，最终落到同一存储。
- `setUp` / `tearDown` 显式清理键，避免与运行环境的真实值串台。

---

## M6-18 示例数据导入完整性测试

**文件：** `NotteTests/UnitTests/ExampleDataFactoryTests.swift`

```swift
import XCTest
@testable import Notte

@MainActor
final class ExampleDataFactoryTests: XCTestCase {

    var collectionRepository: MockCollectionRepository!
    var pageRepository: MockPageRepository!
    var nodeRepository: MockNodeRepository!
    var blockRepository: MockBlockRepository!
    var factory: ExampleDataFactory!

    override func setUp() {
        super.setUp()
        collectionRepository = MockCollectionRepository()
        pageRepository = MockPageRepository()
        nodeRepository = MockNodeRepository()
        blockRepository = MockBlockRepository()
        factory = ExampleDataFactory(
            collectionRepository: collectionRepository,
            pageRepository: pageRepository,
            nodeRepository: nodeRepository,
            blockRepository: blockRepository
        )
    }

    /// 测试：导入 SwiftUILearning 后 Collection 数量 +1，Page 与 Node 数量符合 JSON
    func testImportSwiftUILearning() async throws {
        try await factory.importOne(file: "SwiftUILearning")

        XCTAssertEqual(collectionRepository.storedCollections.count, 1)
        XCTAssertEqual(collectionRepository.storedCollections.first?.title, "SwiftUI 学习")
        XCTAssertEqual(pageRepository.storedPages.count, 3)
        XCTAssertGreaterThanOrEqual(nodeRepository.storedNodes.count, 12)
    }

    /// 测试：导入全部示例后三个 Collection 均存在且 sortIndex 互不冲突
    func testImportAllProducesDistinctSortIndexes() async throws {
        try await factory.importAll()
        let sortIndexes = collectionRepository.storedCollections.map(\.sortIndex)
        XCTAssertEqual(Set(sortIndexes).count, sortIndexes.count, "sortIndex 必须唯一")
        XCTAssertEqual(collectionRepository.storedCollections.count, 3)
    }

    /// 测试：嵌套 Node 的 parentNodeID 指向同一 Page 内的父 Node
    func testNestedNodesLinkToParent() async throws {
        try await factory.importOne(file: "SwiftUILearning")
        let nodes = nodeRepository.storedNodes
        let childNodes = nodes.filter { $0.depth > 0 }
        XCTAssertFalse(childNodes.isEmpty)
        for child in childNodes {
            XCTAssertNotNil(child.parentNodeID)
            XCTAssertTrue(nodes.contains(where: { $0.id == child.parentNodeID }))
        }
    }
}
```

**Git commit message：**

```
test: cover example data factory import integrity
```

**解释：**

- 用 Mock Repository 跑导入，不触碰 SwiftData，关注"导入产生了正确数量和结构的实体"。
- 验证嵌套链路：所有 depth > 0 的 Node 必须有 parent 且 parent 存在于同一次导入中。
- `sortIndex` 唯一性验证：保证后续显示顺序稳定。

---

## M6-19 Onboarding 页面导航 UI 测试

**文件：** `NotteUITests/OnboardingNavigationUITests.swift`

```swift
import XCTest

final class OnboardingNavigationUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// 测试：首次启动展示 onboarding，可以左右滑动到第 3 屏并触发"创建第一个 Collection"
    func testSwipeThroughOnboardingAndCreate() {
        let app = XCUIApplication()
        app.launchArguments += ["-resetOnboarding", "YES"]
        app.launch()

        XCTAssertTrue(app.staticTexts["结构化地记录一切"].waitForExistence(timeout: 3))

        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["三个对象，一套系统"].waitForExistence(timeout: 2))

        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["准备好了吗？"].waitForExistence(timeout: 2))

        app.buttons["创建我的第一个 Collection"].tap()
        // 进入主页后应弹出创建 Sheet
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 3))
    }

    /// 测试：顶部"跳过"直接进入主页且不再展示 onboarding
    func testSkipOnboardingGoesToMain() {
        let app = XCUIApplication()
        app.launchArguments += ["-resetOnboarding", "YES"]
        app.launch()

        XCTAssertTrue(app.buttons["跳过"].waitForExistence(timeout: 3))
        app.buttons["跳过"].tap()
        XCTAssertTrue(app.navigationBars["Notte"].waitForExistence(timeout: 3))

        // 再次启动应直接进入主页
        app.terminate()
        app.launchArguments.removeAll { $0 == "-resetOnboarding" }
        app.launch()
        XCTAssertTrue(app.navigationBars["Notte"].waitForExistence(timeout: 3))
    }
}
```

> **配套改动：** `NotteApp` 在 `init()` 中读取 `-resetOnboarding` 启动参数，若为 `YES` 则把 `hasCompletedOnboarding` 重置为 `false`，便于 UITest 独立运行。

**Git commit message：**

```
test: add onboarding navigation UI tests
```

**附加 commit message：**

```
chore: support resetOnboarding launch argument
```

**解释：**

- UITest 通过启动参数显式重置 onboarding 标记，避免依赖运行顺序或残留状态。
- 两个 case 覆盖主路径：完整三屏 + CTA、跳过 + 持久化。

---

## M6-20 SettingsView 渲染测试

**文件：** `NotteTests/UnitTests/SettingsViewModelTests.swift`

```swift
import XCTest
@testable import Notte

@MainActor
final class SettingsViewModelTests: XCTestCase {

    /// 测试：版本号从 Bundle 读出后格式为 "<version> (<build>)"
    func testAppVersionFormat() {
        let vm = SettingsViewModel()
        XCTAssertTrue(vm.appVersion.contains("("))
        XCTAssertTrue(vm.appVersion.hasSuffix(")"))
        XCTAssertFalse(vm.appVersion.contains("0.0.0 (0)"), "未读取到 Bundle 版本号")
    }
}
```

**Git commit message：**

```
test: verify settings version string format
```

**解释：**

- SettingsView 本身是无状态拼装，渲染快照测试价值不高；这里只回归唯一的动态字段——版本号字符串。
- 通过断言 Bundle 实际值不等于默认 fallback（`0.0.0 (0)`），保证 Info.plist 的 `CFBundleShortVersionString` / `CFBundleVersion` 被正确读取。
