# Notte 配色方案

> 适用阶段：MVP 全程及后续迭代  
> 最后更新：2026-03

---

## 设计原则

- **暖调极简**：以低饱和黄调为品牌底色，区别于 Apple Notes / Craft 的冷白路线
- **浅深统一**：浅色与深色模式共享同一色相族，强调色保持一致色相仅调整明度
- **克制用色**：界面 chrome（背景、边框、文字）保持同色系内，强调色只出现在光标、激活态、链接等关键位置

---

## 浅色模式

| Token | 用途 | Hex |
|---|---|---|
| 主背景 | 页面底色 | `#FDFAF0` |
| 次背景 | 卡片、激活 Node 背景 | `#F5F0DC` |
| 边框 | 分割线、控件描边 | `#E6DFC8` |
| 主文字 | 标题、正文 | `#1C1A14` |
| 次文字 | 占位符、说明文字、meta 信息 | `#6B6458` |
| 强调色 | 光标、激活态、链接、图标 | `#9A7A50` |

### 色板预览

```
主背景  ████  #FDFAF0   纸张黄，主阅读面
次背景  ████  #F5F0DC   稍深，区分卡片层级
边框    ████  #E6DFC8   低调描边，不抢眼
次文字  ████  #6B6458   暖灰，辅助信息
主文字  ████  #1C1A14   近黑，带极轻暖调
强调色  ████  #9A7A50   暖棕金，品牌识别色
```

---

## 深色模式

| Token | 用途 | Hex |
|---|---|---|
| 主背景 | 页面底色 | `#18160F` |
| 次背景 | 卡片、激活 Node 背景 | `#221F14` |
| 边框 | 分割线、控件描边 | `#2E2D28` |
| 主文字 | 标题、正文 | `#EDE8D8` |
| 次文字 | 占位符、说明文字、meta 信息 | `#8C8470` |
| 强调色 | 光标、激活态、链接、图标 | `#C4A46A` |

### 色板预览

```
主背景  ████  #18160F   近黑，带极轻暖黄底调
次背景  ████  #221F14   稍亮，区分卡片层级
边框    ████  #2E2D28   灰调为主，黄调极轻
次文字  ████  #8C8470   暖灰，辅助信息
主文字  ████  #EDE8D8   暖白，长时间阅读舒适
强调色  ████  #C4A46A   强调色亮度提升，保证深色下对比度
```

---

## SwiftUI 使用说明

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
}
```

深色模式跟随系统，通过 `.colorScheme` 环境变量自动切换，无需手动判断。

---

## 版本记录

| 版本 | 日期 | 变更 |
|---|---|---|
| v1.0 | 2026-03 | 初版，确定浅色 + 深色双模式配色 |
