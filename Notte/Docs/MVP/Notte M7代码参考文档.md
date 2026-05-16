# Notte M7 代码参考文档

> 本文档包含 M7（iCloud Sync Beta）阶段所有 issue 的文件路径、代码内容与解释。  
> M7 目标：两设备间基础 CRUD 同步可用，不破坏本地闭环；同步失败时本地数据完整保留。

---

## 分支

```
feature/m7-icloud-sync
```

## 目录

1. [M7-01 Xcode Capabilities 配置（CloudKit 声明）](#m7-01-xcode-capabilities-配置cloudkit-声明)
2. [M7-02 PersistenceController 启用 CloudKit 同步](#m7-02-persistencecontroller-启用-cloudkit-同步)
3. [M7-03 Debug / Production CloudKit 容器隔离](#m7-03-debug--production-cloudkit-容器隔离)
4. [M7-03.5 冲突策略声明（Last Write Wins）](#m7-035-冲突策略声明last-write-wins)
5. [M7-04 CloudKitSyncLogger 实现](#m7-04-cloudkitsynclogger-实现)
6. [M7-05 CloudKit 错误通知监听](#m7-05-cloudkit-错误通知监听)
7. [M7-06 CloudKit 错误映射到 AppError](#m7-06-cloudkit-错误映射到-apperror)
7. [M7-07 SettingsSyncSection 实时同步状态](#m7-07-settingssyncsection-实时同步状态)
8. [M7-08 lastSyncDate AppStorage 追踪](#m7-08-lastsyncdate-appstorage-追踪)
9. [M7-09 同步失败 Toast（RootView）](#m7-09-同步失败-toastrootview)
10. [M7-10 调试分区——手动 CloudKit 同步触发](#m7-10-调试分区手动-cloudkit-同步触发)
11. [M7-11 调试分区——同步日志查看](#m7-11-调试分区同步日志查看)
12. [M7-12 测试：设备 A 创建 Collection，设备 B 接收](#m7-12-测试设备-a-创建-collection设备-b-接收)
13. [M7-13 测试：设备 A 重命名 Page，设备 B 接收](#m7-13-测试设备-a-重命名-page设备-b-接收)
14. [M7-14 测试：设备 A 删除 Node，设备 B 消失](#m7-14-测试设备-a-删除-node设备-b-消失)
15. [M7-15 测试：离线编辑，重连后设备 B 同步](#m7-15-测试离线编辑重连后设备-b-同步)
16. [M7-16 测试：同步失败时本地数据完整性](#m7-16-测试同步失败时本地数据完整性)
17. [M7-17 测试：CloudKit 接入后编辑器无回归](#m7-17-测试cloudkit-接入后编辑器无回归)
18. [M7-18 验收：Collection 列表屏启用同步后无异常](#m7-18-验收collection-列表屏启用同步后无异常)
19. [M7-19 验收：Node 编辑器启用同步后无崩溃](#m7-19-验收node-编辑器启用同步后无崩溃)

---

## M7-01 Xcode Capabilities 配置（CloudKit 声明）

**文件：** Xcode UI 操作，无 Swift 源文件改动

**操作步骤：**

1. Xcode → 选中 `Notte` Target → `Signing & Capabilities` → `+` → 搜索 `iCloud` → 添加
2. 勾选 **CloudKit**
3. 在 `Containers` 下点击 `+` 添加容器：
   - Production：`iCloud.com.markyu000.notte`
   - Debug（可选独立容器）：`iCloud.com.markyu000.notte.debug`
4. 确认 `.entitlements` 文件已包含 `com.apple.developer.icloud-container-identifiers` 和 `com.apple.developer.ubiquity-kvstore-identifier`

> CloudKit 容器 ID 一旦在 Apple Developer Portal 注册后不可更改，命名务必确认后再提交。

**Git commit message：**

```
chore: add CloudKit capability to Xcode project entitlements
```

---

## M7-02 PersistenceController 启用 CloudKit 同步

**文件：** `Data/Persistence/PersistenceController.swift`

```swift
import Foundation
import SwiftData

struct PersistenceController {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)

        if inMemory {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(
                for: schema,
                migrationPlan: NotteMigrationPlan.self,
                configurations: config
            )
        }

        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: NotteMigrationPlan.self,
            configurations: config
        )
    }
}
```

**Git commit message：**

```
feat: enable SwiftData CloudKit sync in ModelContainer
```

**解释：**

- `inMemory: true` 分支保持不变，测试时仍走纯内存路径，不受 CloudKit 影响。
- `cloudKitDatabase: .automatic` 让 SwiftData 自动选取 Entitlements 中声明的第一个 CloudKit 容器，冲突策略默认为 Last Write Wins——`CollectionModel`、`PageModel`、`NodeModel`、`BlockModel` 都带有 `updatedAt`，CloudKit 以此决定最新版本。
- 不传 `cloudKitDatabase` 时默认值为 `.none`，即原有行为——所以此改动仅对真机/实机容器生效，不影响 `inMemory` 路径。

---

## M7-03 Debug / Production CloudKit 容器隔离

**文件：** `Data/Persistence/PersistenceController.swift`

```swift
import Foundation
import SwiftData

struct PersistenceController {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)

        if inMemory {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(
                for: schema,
                migrationPlan: NotteMigrationPlan.self,
                configurations: config
            )
        }

        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: cloudKitDatabase
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: NotteMigrationPlan.self,
            configurations: config
        )
    }

    private static var cloudKitDatabase: ModelConfiguration.CloudKitDatabase {
        #if DEBUG
        return .private("iCloud.com.markyu000.notte.debug")
        #else
        return .automatic
        #endif
    }
}
```

**Git commit message：**

```
feat: use separate CloudKit container for debug builds
```

**解释：**

- Debug 构建使用独立容器，避免开发过程中的脏数据污染用户的 Production 数据。
- `#if DEBUG` 在 Swift 中是编译期条件，不会增加 Release 包体积。
- `.private("iCloud.com.markyu000.notte.debug")` 对应 Developer Portal 中注册的独立容器；Release 使用 `.automatic`，自动匹配 Entitlements 的第一个生产容器。

---

## M7-03.5 冲突策略声明（Last Write Wins）

**文件：** 无代码改动，工程决策记录

**冲突策略：** Last Write Wins（LWW）

SwiftData + CloudKit 默认冲突策略即为 LWW，无需额外代码实现。当两台设备对同一条记录做出相互冲突的修改时，CloudKit 以 `updatedAt` 字段决定保留哪一版本。

**前提：** 四个 `@Model` 类均带有 `updatedAt: Date` 字段（M1 阶段已建立），每次写操作必须同步更新该字段：

| 模型 | `updatedAt` 更新时机 |
|---|---|
| `CollectionModel` | 重命名、固定/取消固定、重排序 |
| `PageModel` | 重命名、归档、重排序 |
| `NodeModel` | 标题变更、缩进/反缩进、移动、折叠 |
| `BlockModel` | 内容变更 |

**已知局限：**

- LWW 不处理结构性冲突（如两端同时移动同一 Node 的父子关系）。MVP 阶段接受此限制，不引入合并 UI，后续可在 M8 回归测试中增加"双端同时编辑同一 Node 标题"用例验证。
- 若两端系统时钟差异过大，LWW 结果可能不符合直觉——这是 CloudKit LWW 的固有特性，MVP 不作额外处理。

**Git commit message：**

```
docs: record LWW conflict strategy as engineering decision for M7
```

---

## M7-04 CloudKitSyncLogger 实现

**文件：** `Data/Sync/CloudKitSyncLogger.swift`（新建）

```swift
import Foundation
import CoreData

/// 监听 SwiftData + CloudKit 底层的同步事件，向 UI 层暴露同步状态。
/// SwiftData 的 CloudKit 集成底层仍通过 NSPersistentCloudKitContainer 发出通知。
@MainActor
final class CloudKitSyncLogger: ObservableObject {

    struct SyncEvent: Identifiable {
        let id = UUID()
        let date: Date
        let eventType: String
        let succeeded: Bool
        let errorDescription: String?
    }

    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncFailed: Bool = false
    @Published private(set) var syncError: Error?
    @Published private(set) var eventLog: [SyncEvent] = []

    private var observer: NSObjectProtocol?
    private let maxLogSize = 50

    init() {
        restoreLastSyncDate()
    }

    deinit {
        // deinit 不受 @MainActor 约束，可能在任意线程被调用；
        // NotificationCenter.removeObserver 是线程安全的，可直接调用。
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let event = notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event
            else { return }
            Task { @MainActor [weak self] in
                self?.handle(event: event)
            }
        }
    }

    private func restoreLastSyncDate() {
        let ts = UserDefaults.standard.double(forKey: "lastSyncDate")
        lastSyncDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    private func handle(event: NSPersistentCloudKitContainer.Event) {
        let typeName: String
        switch event.type {
        case .setup:   typeName = "setup"
        case .import:  typeName = "import"
        case .export:  typeName = "export"
        @unknown default: typeName = "unknown"
        }

        let logEntry = SyncEvent(
            date: event.endDate ?? Date(),
            eventType: typeName,
            succeeded: event.succeeded,
            errorDescription: event.error?.localizedDescription
        )
        eventLog.insert(logEntry, at: 0)
        if eventLog.count > maxLogSize { eventLog.removeLast() }

        if let error = event.error {
            syncFailed = true
            syncError = error
        } else if event.succeeded && event.type != .setup {
            // .setup 事件表示 CloudKit schema 初始化完成，不代表用户数据已同步，
            // 不应记录为"上次同步时间"。
            syncFailed = false
            syncError = nil
            let now = event.endDate ?? Date()
            lastSyncDate = now
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "lastSyncDate")
        }
    }
}
```

**Git commit message：**

```
feat: add CloudKit sync event logger
```

**解释：**

- `startObserving()` 与 `init()` 分离：`AppBootStrap` 在 `isReady = true` 后再调用，确保 `ModelContainer` 已就绪。
- `SyncEvent` 保留最近 50 条记录，供调试分区展示，不写入持久化。
- `lastSyncDate` 在 init 时从 `UserDefaults` 恢复，使设置页重启后不显示"尚未同步"。
- `event.type != .setup` 过滤掉 schema 初始化事件：`.setup` 仅代表 CloudKit 容器结构建立完成，不意味着用户数据已完成 import/export，不应将其时间戳记录为"上次同步"。
- `@unknown default` 保护未来 Apple 新增事件类型时不崩溃。

---

## M7-05 CloudKit 错误通知监听

**文件：** `App/AppBootStrap.swift`（新增 `syncLogger` 属性，在 `isReady = true` 后启动监听）

```swift
import Combine
import SwiftData

@MainActor
class AppBootStrap: ObservableObject {
    @Published var isReady: Bool = false
    let modelContainer: ModelContainer
    private(set) var dependencyContainer: DependencyContainer?
    let syncLogger = CloudKitSyncLogger()

    init() {
        do {
            modelContainer = try PersistenceController.makeContainer()
            dependencyContainer = DependencyContainer(modelContainer: modelContainer)
            isReady = true
            syncLogger.startObserving()
        } catch {
            fatalError("SwiftData初始化失败：\(error)")
        }
    }
}
```

**文件：** `App/NotteApp.swift`（注入 `syncLogger` 为 EnvironmentObject）

```swift
import SwiftUI
import SwiftData

@main
struct NotteApp: App {
    @StateObject private var appBootstrap = AppBootStrap()

    var body: some Scene {
        WindowGroup {
            if appBootstrap.isReady {
                RootView()
                    .environmentObject(appBootstrap)
                    .environmentObject(appBootstrap.dependencyContainer!)
                    .environmentObject(appBootstrap.syncLogger)
            } else {
                ProgressView("启动中...")
            }
        }
        .modelContainer(appBootstrap.modelContainer)
    }
}
```

**Git commit message：**

```
feat: wire CloudKit sync logger into app bootstrap and environment
```

**解释：**

- `syncLogger` 作为 `EnvironmentObject` 从 `NotteApp` 顶层注入，所有下游视图（Settings、RootView 的 Toast）直接读取，无需层层传参。
- `startObserving()` 在 `isReady = true` 之后调用，保证此时 `ModelContainer` 已初始化，CloudKit 同步已激活，不会漏掉早期事件。

---

## M7-06 CloudKit 错误映射到 AppError

**文件：** `Infrastructure/AppError.swift`（新增 `syncFailed` case）

```swift
enum AppError: Error {
    // 现有 case（以实际文件为准，此处仅展示新增内容）
    case repositoryError(RepositoryError)
    // M7 新增：CloudKit 同步层专用错误域
    case syncFailed(Error)
}
```

**文件：** `Data/Sync/CloudKitSyncLogger.swift`（`handle(event:)` 直接保存原始 `Error`，不做跨层包装）

```swift
// handle(event:) 的错误处理分支——已体现在 M7-04 完整实现中
if let error = event.error {
    syncFailed = true
    syncError = error   // 保存原始 Error，不在 Data 层包装为 AppError
}
```

需要向用户展示精确错误或进行日志上报时，在**表现层边界**处转换：

```swift
// 示例：在 Alert / 错误上报处按需转换
let appError = AppError.syncFailed(syncLogger.syncError ?? SyncUnknownError())
```

**Git commit message：**

```
feat: add AppError.syncFailed case for CloudKit errors
```

**解释：**

- `RepositoryError` 是持久化层（SwiftData CRUD）的错误域，不适合描述 CloudKit 网络/权限/配额错误——两者错误语义不同，不应共用。
- `CloudKitSyncLogger.syncError: Error?` 保存原始 CloudKit 错误，Data 层不做跨层包装，保持层级清洁。
- `AppError.syncFailed(Error)` 作为表现层的映射点：MVP 阶段 `SyncFailureBanner` 只需判断 `syncFailed: Bool`，无需展开具体类型；此 case 为 M8 阶段精细错误展示（错误类型分类、用户友好提示）预留接口。

---

## M7-07 SettingsSyncSection 实时同步状态

**文件：** `Features/Settings/Views/SettingsSyncSection.swift`

```swift
import SwiftUI

struct SettingsSyncSection: View {
    @EnvironmentObject private var syncLogger: CloudKitSyncLogger

    var body: some View {
        Section("iCloud 同步") {
            HStack(spacing: SpacingTokens.sm) {
                Image(systemName: syncLogger.syncFailed ? "icloud.slash" : "icloud")
                    .foregroundStyle(syncLogger.syncFailed ? ColorTokens.textSecondary : Color.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(syncLogger.syncFailed ? "同步失败" : "已开启")
                        .font(TypographyTokens.body)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(formattedLastSync)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer()
            }
            .padding(.vertical, 2)

            Text("你的 Collection、Page、Node 将自动同步到所有 Apple 设备。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }

    private var formattedLastSync: String {
        guard let date = syncLogger.lastSyncDate else { return "尚未同步" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return "上次同步：\(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
```

**Git commit message：**

```
feat: update iCloud sync section with real-time status
```

**解释：**

- 替换 M6 阶段的占位文案（"即将推出"），接入真实的 `CloudKitSyncLogger` 状态。
- `syncFailed` 为 `true` 时图标切换为 `icloud.slash`，视觉上立即提示用户注意。
- `RelativeDateTimeFormatter` 输出自然语言时间（"3 分钟前"），避免精确时间戳带来的认知负担。

---

## M7-08 lastSyncDate AppStorage 追踪

**文件：** `Data/Sync/CloudKitSyncLogger.swift`（已在 M7-04 实现，此处说明持久化策略）

`lastSyncDate` 写入路径：

```swift
// handle(event:) 成功分支
let now = event.endDate ?? Date()
lastSyncDate = now
UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "lastSyncDate")
```

读取路径（init 时恢复）：

```swift
private func restoreLastSyncDate() {
    let ts = UserDefaults.standard.double(forKey: "lastSyncDate")
    lastSyncDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
}
```

**文件：** `Features/Settings/ViewModels/SettingsViewModel.swift`（保持不变，同步时间由 `CloudKitSyncLogger` 直接提供给 View）

**Git commit message：**

```
feat: persist last sync date to UserDefaults
```

**解释：**

- 使用 `UserDefaults` 而非 `AppStorage`：`CloudKitSyncLogger` 是 `Data` 层对象，不应依赖 SwiftUI 的 `@AppStorage`；手动读写 `UserDefaults` 保持层级清洁。
- 存储 `timeIntervalSince1970`（`Double`）而非 `Date`，兼容性好，不依赖 `PropertyListEncoder`。
- `lastSyncDate` 只记录 `succeeded` 且类型不为 `.setup` 的事件，避免 schema 初始化误被记录为"同步完成"。

---

## M7-09 同步失败 Toast（RootView）

**文件：** `App/RootView.swift`（在 `mainNavigation` 上叠加 banner）

```swift
// RootView.swift — 新增 syncLogger 和 banner overlay
struct RootView: View {
    @EnvironmentObject private var syncLogger: CloudKitSyncLogger
    // ... 其余属性不变 ...

    var body: some View {
        ZStack {
            // ... 现有 onboarding / mainNavigation 切换逻辑不变 ...
        }
        .animation(.easeInOut(duration: 0.45), value: hasCompletedOnboarding)
        .overlay(alignment: .top) {
            if syncLogger.syncFailed {
                SyncFailureBanner()
                    .padding(.top, SpacingTokens.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: syncLogger.syncFailed)
    }
}
```

**文件：** `Shared/Components/SyncFailureBanner.swift`（新建）

```swift
import SwiftUI

/// 同步失败时显示在屏幕顶部的横幅提示。
/// 仅在 CloudKitSyncLogger.syncFailed == true 时由 RootView 展示。
struct SyncFailureBanner: View {
    var body: some View {
        Label("iCloud 同步失败，数据已安全保存在本地", systemImage: "icloud.slash")
            .font(TypographyTokens.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, SpacingTokens.md)
            .padding(.vertical, SpacingTokens.sm + 2)
            .background(Color.red.opacity(0.85), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}
```

**Git commit message：**

```
feat: show sync failure banner in root view
```

**解释：**

- Banner 放在 `RootView` 的 `.overlay` 而非各功能屏内部，保证无论用户在哪个页面都能看到。
- 文案强调"数据已安全保存在本地"，降低用户对数据丢失的焦虑。
- 使用 `spring(duration: 0.3)` 动画让 banner 滑入/滑出有弹性感，与 App 整体动画风格一致。

---

## M7-10 调试分区——手动 CloudKit 同步触发

**文件：** `Features/Settings/Views/SettingsDebugSection.swift`（新增同步相关按钮）

```swift
#if DEBUG
struct SettingsDebugSection: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    @EnvironmentObject private var syncLogger: CloudKitSyncLogger
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isImporting: Bool = false
    @State private var showSyncLog: Bool = false

    var body: some View {
        Section("调试") {
            // 原有按钮保持不变
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

            // M7 新增：同步相关
            Button {
                triggerSyncRefresh()
            } label: {
                Label("触发数据刷新", systemImage: "arrow.clockwise.icloud")
            }

            Button {
                showSyncLog = true
            } label: {
                Label("查看同步日志", systemImage: "list.bullet.clipboard")
            }
        }
        .sheet(isPresented: $showSyncLog) {
            SyncLogSheet(logger: syncLogger)
        }
    }

    private func clearAllData() {
        try? modelContext.delete(model: CollectionModel.self)
        try? modelContext.delete(model: PageModel.self)
        try? modelContext.delete(model: NodeModel.self)
        try? modelContext.delete(model: BlockModel.self)
        try? modelContext.save()
    }

    private func triggerSyncRefresh() {
        // SwiftData + CloudKit 同步由框架自动调度，
        // 此处通过刷新 context 中的所有对象来尝试触发推拉。
        modelContext.refreshAllObjects()
    }
}
#endif
```

**Git commit message：**

```
feat: add sync refresh trigger to debug section
```

**解释：**

- `modelContext.refreshAllObjects()` 强制 context 从持久化层重新读取所有对象，CloudKit 的推拉调度由 SwiftData 内部的 `NSPersistentCloudKitContainer` 决定，调用此方法后框架通常会安排一次 export/import 检查。
- 不提供"强制推送"按钮：SwiftData 未暴露公开 API 手动触发推送，框架在数据变更后会自动在合适时机上传。

---

## M7-11 调试分区——同步日志查看

**文件：** `Features/Settings/Views/SyncLogSheet.swift`（新建，仅 `#if DEBUG`）

```swift
import SwiftUI

#if DEBUG
struct SyncLogSheet: View {
    @ObservedObject var logger: CloudKitSyncLogger
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if logger.eventLog.isEmpty {
                    Text("暂无同步记录")
                        .foregroundStyle(ColorTokens.textSecondary)
                        .font(TypographyTokens.body)
                } else {
                    ForEach(logger.eventLog) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: event.succeeded ? "checkmark.circle" : "xmark.circle")
                                    .foregroundStyle(event.succeeded ? Color.green : Color.red)
                                Text(event.eventType.uppercased())
                                    .font(TypographyTokens.caption.weight(.semibold))
                                    .foregroundStyle(ColorTokens.textSecondary)
                                Spacer()
                                Text(event.date, format: .dateTime.hour().minute().second())
                                    .font(TypographyTokens.caption)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                            if let errorDesc = event.errorDescription {
                                Text(errorDesc)
                                    .font(TypographyTokens.caption)
                                    .foregroundStyle(Color.red)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("同步日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
#endif
```

**Git commit message：**

```
feat: add sync event log viewer in debug section
```

**解释：**

- `SyncLogSheet` 只在 `#if DEBUG` 编译，Release 包体积不受影响。
- 最多展示 50 条（`CloudKitSyncLogger.maxLogSize`），时间倒序排列（最新在顶）。
- 事件类型分为 `SETUP`、`IMPORT`、`EXPORT`，颜色区分成功/失败，出错时展示 `localizedDescription`。

---

## M7-12 测试：设备 A 创建 Collection，设备 B 接收

**类型：** 手动跨设备测试（需两台已登录同一 iCloud 账号的真机）

**步骤：**

1. 设备 A：打开 Notte，创建新 Collection「同步测试 A」
2. 等待约 30 秒（CloudKit 推拉间隔）
3. 设备 B：打开 Notte，Collection 列表刷新
4. 断言：设备 B 出现「同步测试 A」，标题一致

**验收：**

- [ ] 设备 B 在 30 秒内出现新 Collection
- [ ] 设备 B 的 SettingsSyncSection 显示"上次同步：刚刚"

---

## M7-13 测试：设备 A 重命名 Page，设备 B 接收

**类型：** 手动跨设备测试

**步骤：**

1. 两设备已完成 M7-12 同步基准
2. 设备 A：进入「同步测试 A」，将已有 Page 重命名为「同步页面 v2」
3. 等待约 30 秒
4. 设备 B：进入同一 Collection

**验收：**

- [ ] 设备 B 显示「同步页面 v2」，未出现重复 Page
- [ ] 设备 B 的 Page 列表中旧名称「同步页面 v1」已不存在

---

## M7-14 测试：设备 A 删除 Node，设备 B 消失

**类型：** 手动跨设备测试

**步骤：**

1. 设备 A：进入某 Page，删除一个 Node（含子节点）
2. 等待约 30 秒
3. 设备 B：打开同一 Page

**验收：**

- [ ] 设备 B 对应 Node 及其所有子节点均消失
- [ ] 设备 B 页面结构与设备 A 完全一致

---

## M7-15 测试：离线编辑，重连后设备 B 同步

**类型：** 手动跨设备测试

**步骤：**

1. 设备 A：关闭 Wi-Fi 和蜂窝网络（飞行模式）
2. 设备 A：创建 Node「离线笔记」并编辑内容
3. 设备 A：恢复网络
4. 等待约 60 秒
5. 设备 B：打开对应 Page

**验收：**

- [ ] 设备 B 出现「离线笔记」，内容与设备 A 一致
- [ ] 设备 A 的 SettingsSyncSection 恢复为"已开启"状态
- [ ] `syncFailed` Toast 在设备 A 网络恢复且同步成功后自动消失

---

## M7-16 测试：同步失败时本地数据完整性

**文件：** `NotteTests/UnitTests/LocalDataIntegrityTests.swift`（新建）

使用 `inMemory` 容器等价模拟"CloudKit 完全不可用"状态（网络断开 / 同步失败），验证本地 Repository 层的 CRUD 操作不受影响。

```swift
import XCTest
import SwiftData
@testable import Notte

/// 验证同步不可用时本地数据完整性：
/// inMemory 容器 = CloudKit 同步路径被完全旁路，只剩本地存储层。
@MainActor
final class LocalDataIntegrityTests: XCTestCase {

    var container: ModelContainer!
    var collectionRepo: CollectionRepository!
    var nodeRepo: NodeRepository!

    override func setUpWithError() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        collectionRepo = CollectionRepository(context: context)
        nodeRepo = NodeRepository(context: context)
    }

    /// 测试：CloudKit 不可用时，Collection CRUD 完整可用
    func testCollectionCRUDWithoutCloudKit() async throws {
        let id = UUID()
        let collection = Collection(
            id: id,
            title: "本地 Collection",
            iconName: nil,
            colorToken: nil,
            createdAt: Date(),
            updatedAt: Date(),
            sortIndex: 1000,
            isPinned: false
        )
        try await collectionRepo.create(collection)

        let all = try await collectionRepo.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, id)
        XCTAssertEqual(all.first?.title, "本地 Collection")
    }

    /// 测试：CloudKit 不可用时，Node 写入后本地仍可独立读取
    func testNodeDataPersistsLocallyWithoutCloudKit() async throws {
        let nodeID = UUID()
        let node = Node(
            id: nodeID,
            pageID: UUID(),
            parentNodeID: nil,
            title: "离线节点",
            depth: 0,
            sortIndex: 1000,
            isCollapsed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await nodeRepo.create(node)

        let fetched = try await nodeRepo.fetch(by: nodeID)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "离线节点")
    }

    /// 测试：连续多次写入，数据量准确，无静默丢失
    func testConsecutiveWritesDontLoseData() async throws {
        let pageID = UUID()
        let ids = (0..<5).map { _ in UUID() }
        for (i, id) in ids.enumerated() {
            let node = Node(
                id: id,
                pageID: pageID,
                parentNodeID: nil,
                title: "节点 \(i)",
                depth: 0,
                sortIndex: Double(i + 1) * 1000,
                isCollapsed: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await nodeRepo.create(node)
        }
        for id in ids {
            let fetched = try await nodeRepo.fetch(by: id)
            XCTAssertNotNil(fetched, "节点 \(id) 写入后应可本地读取")
        }
    }
}
```

**Git commit message：**

```
test: verify local data integrity when CloudKit sync is unavailable
```

**解释：**

- `inMemory` 容器等价于"CloudKit 路径完全不工作"的状态：数据只写入本地内存，不经过任何 CloudKit 网络调用——这正是同步失败时应当成立的保证。
- 三个测试分别验证：单条创建后可读取（Collection）、Node 独立读取、批量写入无丢失。覆盖"同步失败不破坏本地闭环"的核心验收条件。
- 使用真实 `CollectionRepository` / `NodeRepository`（非 Mock），确保验证的是完整的数据层路径而非测试替身。

---

## M7-17 测试：CloudKit 接入后编辑器无回归

**类型：** 手动回归 + 关键路径自动化

**手动检查清单（在已启用 CloudKit 的真机上执行）：**

- [ ] 创建 Node → 回车插入下一节点 → 焦点正常转移
- [ ] Tab 缩进 3 层 → Shift+Tab 反缩进 → 结构正确
- [ ] 删除有子节点的 Node → 子节点级联消失
- [ ] 折叠 / 展开包含 5 层子节点的 Node → 可见性正确
- [ ] 退出 PageEditor → 重进 → 数据不丢（包含 Block 内容）
- [ ] 100 个节点页面滚动流畅，无明显卡顿

**自动化回归：** 运行现有测试套件：

```bash
xcodebuild test -scheme Notte \
  -destination "platform=iOS Simulator,name=iPhone 16"
```

**验收：** 所有已有单元测试通过，无新增失败。

---

## M7-18 验收：Collection 列表屏启用同步后无异常

**类型：** 手动验收（真机）

**检查清单：**

- [ ] 冷启动后 Collection 列表正常加载，无加载超时
- [ ] 创建 / 删除 / 重命名 / 固定 Collection 操作均正常
- [ ] SettingsSyncSection 显示正确的同步状态和时间
- [ ] 深色模式下 SyncFailureBanner 颜色与主题一致

---

## M7-19 验收：Node 编辑器启用同步后无崩溃

**类型：** 手动验收（真机）

**检查清单：**

- [ ] 打开含大量节点（50+）的 Page，编辑器正常加载
- [ ] 连续快速输入标题内容，debounce 自动保存正常触发
- [ ] 切换到后台再切回，数据未丢失
- [ ] 两设备同时打开同一 Page 并编辑——Last Write Wins，无崩溃
- [ ] 设置页"触发数据刷新"后编辑器未受影响（DEBUG 构建）
