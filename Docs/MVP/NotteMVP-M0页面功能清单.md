# Notte 页面功能清单

**阶段** M0 · Definition  
**用途** 低保真线框草图参考 · 明确每个页面必须出现的功能  
**范围** MVP（iPhone 主路径）

---

## 页面导航结构

```
Collection 列表页
  └─ Page 列表页
       └─ Node Editor 页
```

---

## 1. Collection 列表页

**入口**：App 启动后的根页面。

### 导航栏
- 左侧：App 标题 "Notte"
- 右侧：新建 Collection 按钮（`+`）

### 列表内容
- 已固定区（`isPinned = true` 的 Collection 置顶，独立分区标题）
- 全部区（其余 Collection，按 `sortIndex` 排列）
- 每行显示：图标、Collection 名称、Page 数量

### 交互
- 点击行：进入对应 Collection 的 Page 列表页
- 长按行：进入编辑模式（重命名、固定/取消固定）
- 左滑行：显示删除按钮（删除需二次确认）
- 右滑行：快速固定/取消固定
- 拖拽排序：调整 `sortIndex`

### 新建 Collection
- 点击 `+` 后弹出 Sheet
- 输入 Collection 名称（必填）
- 选择图标（`iconName`，MVP 提供有限预设）
- 选择颜色标签（`colorToken`，MVP 提供有限预设）
- 确认后创建并跳转进入

### 空态
- 无任何 Collection 时：显示引导插图 + 文案 + 新建按钮
- 不显示空白列表

---

## 2. Page 列表页

**入口**：从 Collection 列表页点击任意 Collection 进入。

### 导航栏
- 左侧：返回按钮（返回 Collection 列表页）
- 中间：当前 Collection 名称
- 右侧：新建 Page 按钮（`+`）

### 列表内容
- 全部 Page（`isArchived = false`），按 `sortIndex` 排列
- 每行显示：Page 标题、最后修改时间、Node 数量

### 交互
- 点击行：进入对应 Page 的 Node Editor 页
- 左滑行：删除按钮（删除需二次确认，级联删除所有 Node）
- 右滑行：归档按钮（将 Page `isArchived` 设为 true，从列表移除）
- 拖拽排序：调整 `sortIndex`

### 新建 Page
- 点击 `+` 后立即创建一个无标题 Page，并跳转进入 Node Editor
- Page 标题在 Node Editor 内 inline 编辑

### 空态
- 无任何 Page 时：显示引导文案 + 新建按钮
- 不显示空白列表

---

## 3. Node Editor 页

**入口**：从 Page 列表页点击任意 Page 进入。

### 导航栏
- 左侧：返回按钮（返回 Page 列表页，自动保存）
- 右侧：更多操作按钮（`···`）→ 菜单包含：重命名 Page、归档 Page、删除 Page

### Page 标题区
- 位于 Node 列表上方
- 可 inline 编辑（点击后进入编辑模式）
- 空时显示占位文字"无标题"

### Node 树列表
- 按 `sortIndex` 顺序渲染，`depth` 决定视觉缩进层级
- 每个 Node 行显示：
  - 折叠/展开按钮（有子节点时可见，控制 `isCollapsed`）
  - Node 标题（可编辑的 `TextField`）
  - Block 文字内容（Node 标题下方，可编辑）

### 键盘交互
- `Enter`：在当前 Node 后新建同级 Node，光标移入新 Node
- `Backspace`（行首时）：当 Node 为空则删除，当 Node 有内容则与上一 Node 合并
- `Tab`：缩进（增加 `depth`，成为上一 Node 的子节点）
- `Shift+Tab`：反缩进（减少 `depth`）

### 键盘工具条（键盘正上方）
工具条随键盘弹起/收起，包含以下按钮：
- 缩进（同 Tab）
- 反缩进（同 Shift+Tab）
- 上移（将当前 Node 与上一 Node 交换 `sortIndex`）
- 下移（将当前 Node 与下一 Node 交换 `sortIndex`）
- 新增（在当前 Node 后插入新 Node）

### 折叠/展开
- 点击折叠按钮：切换 `isCollapsed`
- `isCollapsed = true` 时，子节点在视图中隐藏
- 折叠状态持久化（写入 SwiftData）

### 保存
- 自动保存：编辑停止后写入 SwiftData，无手动保存按钮
- 返回导航时确保最新状态已落盘

### 空态（新建 Page 首次进入）
- Page 标题区显示占位"无标题"并自动聚焦
- 提示文案"点击开始输入 · Enter 新增节点"
- 工具条中缩进/移动按钮在无 Node 时置灰禁用

---

## 4. 全局 / 跨页面功能

### 持久化
- 所有数据写入 SwiftData 本地存储
- App 重启后数据完整保留

### 深浅色模式
- 所有页面适配系统深色模式

### iCloud 同步（M7 接入，M0 阶段不开发）
- MVP 阶段作为可关闭开关预留，不影响本地主路径

---

## 不在以上页面出现的功能（OUT）

以下功能不在 MVP 范围内，不出现在任何页面：

- 搜索（全局或页面内）
- 标签 / 过滤 / 排序切换
- 图片、代码块、引用块等非纯文字 Block
- 导出（PDF / Markdown / 图片）
- 分享 / 协作
- AI 摘要 / AI 建议
- 思维导图视图（Map View）
- 归档列表入口（归档操作存在，但归档内容的查看界面为 POST）
- 设置页（M6 阶段实现）
- Onboarding 引导流（M6 阶段实现）

---

> 判断原则：任何不在 `Collection → Page → Node → Block` 主路径上的功能，都不进入 MVP。
