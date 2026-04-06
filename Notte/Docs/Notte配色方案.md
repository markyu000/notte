# Notte 配色方案

> 适用阶段：MVP 全程及后续迭代  
> 最后更新：2026-04

---

## 设计原则

- **纯色背景**：浅色用纯白，深色用纯黑，背景类完全不带黄调
- **浅深统一**：次文字、强调色、工具栏色在浅色与深色模式下使用完全相同的黄色值
- **高饱和黄**：品牌色采用高饱和纯正黄，严禁降低饱和度（避免屎黄感）；工具栏用稍深一档的黄以形成层次

---

## 浅色模式

| Token | 用途 | Hex |
|---|---|---|
| 主背景 | 页面底色 | `#FFFFFF` |
| 次背景 | 卡片、激活 Node 背景 | `#F5F5F5` |
| 边框 | 分割线、控件描边 | `#E0E0E0` |
| 主文字 | 标题、正文 | `#000000` |
| 次文字 | 占位符、说明文字、meta 信息 | `#FFE64D` |
| 强调色 | 光标、激活态、链接、图标 | `#FFD300` |
| 工具栏色 | 工具栏背景、工具栏图标底色 | `#FFD300` |

### 色板预览

```
主背景   ████  #FFFFFF   纯白
次背景   ████  #F5F5F5   淡灰，区分卡片层级
边框     ████  #E0E0E0   中性灰描边
主文字   ████  #000000   纯黑
次文字   ████  #FFF176   高饱和浅黄，占位符 / meta
强调色   ████  #FFF176   高饱和浅黄，光标 / 激活态
工具栏色 ████  #EDD000   纯正黄，较深，工具栏背景
```

---

## 深色模式

| Token | 用途 | Hex |
|---|---|---|
| 主背景 | 页面底色 | `#000000` |
| 次背景 | 卡片、激活 Node 背景 | `#1C1C1E` |
| 边框 | 分割线、控件描边 | `#3A3A3C` |
| 主文字 | 标题、正文 | `#FFFFFF` |
| 次文字 | 占位符、说明文字、meta 信息 | `#FFE64D` |
| 强调色 | 光标、激活态、链接、图标 | `#FFD300` |
| 工具栏色 | 工具栏背景、工具栏图标底色 | `#FFD300` |

### 色板预览

```
主背景   ████  #000000   纯黑
次背景   ████  #1C1C1E   深灰，区分卡片层级（Apple 系统深色）
边框     ████  #3A3A3C   中性深灰描边
主文字   ████  #FFFFFF   纯白
次文字   ████  #FFF176   高饱和浅黄，与浅色模式一致
强调色   ████  #FFF176   高饱和浅黄，与浅色模式一致
工具栏色 ████  #EDD000   与浅色模式一致
```

---

## SwiftUI 使用说明

次文字、强调色、工具栏色在 Light / Dark 下值完全相同，Asset Catalog 中 Color Set 的 Light 与 Dark appearance 可填写相同 Hex 值。

在 Asset Catalog 中为每个 Token 创建 Color Set，分别配置 Light / Dark appearance。

```swift
// 示例：在 SwiftUI 中引用
extension Color {
    static let notteBackground         = Color("BackgroundPrimary")
    static let notteBackgroundSecondary = Color("BackgroundSecondary")
    static let notteBorder             = Color("Border")
    static let notteTextPrimary        = Color("TextPrimary")
    static let notteTextSecondary      = Color("TextSecondary")
    static let notteAccent             = Color("Accent")
    static let notteToolbar            = Color("Toolbar")
}
```

深色模式跟随系统，通过 `.colorScheme` 环境变量自动切换，无需手动判断。

---

## 版本记录

| 版本 | 日期 | 变更 |
|---|---|---|
| v1.0 | 2026-03 | 初版，确定浅色 + 深色双模式配色（暖调黄底） |
| v2.0 | 2026-04 | 重新设计：背景改为纯白/纯黑，品牌色改为高饱和纯正黄（`#FFF176` / `#EDD000`），新增工具栏色 Token |
