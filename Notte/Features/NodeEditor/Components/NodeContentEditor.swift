//
//  NodeContentEditor.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

import SwiftUI
import UIKit

/// UITextView 的 SwiftUI 包装，用于 Block 内容的多行输入。
/// 回车键插入换行；Backspace 在空内容时触发 onBackspaceWhenEmpty。
///
/// requestFocus：一次性聚焦请求（父视图写 true），updateUIView 消费后异步重置为 false，
/// 同时将光标移到末尾。用户直接点击 UITextView 时不会触发此路径，因此不会出现双光标。
/// 聚焦/失焦事件通过 onFocusGained / onFocusLost 回调通知父视图，
/// 调用方在 onFocusLost 里用 withAnimation 驱动收起动画。
struct NodeContentEditor: UIViewRepresentable {

    var text: String
    var font: Font
    var placeholder: String
    @Binding var requestFocus: Bool

    var onTextChanged: (String) -> Void
    var onBackspaceWhenEmpty: () -> Void
    var onFocusGained: () -> Void
    var onFocusLost: () -> Void
    var onTab: () -> Void = {}
    var onShiftTab: () -> Void = {}
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}
    var onDelete: () -> Void = {}
    var canIndent: Bool = true

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.inputAccessoryView = makeInputAccessoryView(coordinator: context.coordinator)
        return textView
    }

    private func makeInputAccessoryView(coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 54)
        let deleteItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.didTapDelete)
        )
        deleteItem.tintColor = .systemRed
        let indentItem = UIBarButtonItem(
            image: UIImage(systemName: "increase.indent"),
            style: .plain, target: coordinator,
            action: #selector(Coordinator.didTapIndent)
        )
        indentItem.isEnabled = canIndent
        coordinator.indentItem = indentItem
        toolbar.items = [
            UIBarButtonItem(
                image: UIImage(systemName: "decrease.indent"),
                style: .plain, target: coordinator,
                action: #selector(Coordinator.didTapOutdent)
            ),
            indentItem,
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.up"),
                style: .plain, target: coordinator,
                action: #selector(Coordinator.didTapMoveUp)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.down"),
                style: .plain, target: coordinator,
                action: #selector(Coordinator.didTapMoveDown)
            ),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            deleteItem
        ]
        return toolbar
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(fitting.height, uiView.font?.lineHeight ?? 20))
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.indentItem?.isEnabled = canIndent
        // 非编辑状态下才同步文本/占位符，避免打断用户输入
        if !uiView.isFirstResponder {
            if text.isEmpty {
                uiView.text = placeholder
                uiView.textColor = UIColor(ColorTokens.textSecondary)
            } else if uiView.text != text {
                uiView.text = text
                uiView.textColor = UIColor(ColorTokens.textPrimary)
            }
        }
        // 消费一次性聚焦请求：仅标题回车等程序化场景会进入此分支
        if requestFocus && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            let end = uiView.endOfDocument
            uiView.selectedTextRange = uiView.textRange(from: end, to: end)
            // 用捕获的 binding 异步重置，避免在 updateUIView 调用期间直接写 State
            let binding = $requestFocus
            DispatchQueue.main.async { binding.wrappedValue = false }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: NodeContentEditor
        var indentItem: UIBarButtonItem?

        init(_ parent: NodeContentEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard textView.textColor != UIColor(ColorTokens.textSecondary) else { return }
            parent.onTextChanged(textView.text ?? "")
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == UIColor(ColorTokens.textSecondary) {
                textView.text = ""
                textView.textColor = UIColor(ColorTokens.textPrimary)
            }
            let cb = parent.onFocusGained
            DispatchQueue.main.async { cb() }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor(ColorTokens.textSecondary)
            }
            let cb = parent.onFocusLost
            DispatchQueue.main.async { cb() }
        }

        @objc func didTapIndent() { parent.onTab() }
        @objc func didTapOutdent() { parent.onShiftTab() }
        @objc func didTapMoveUp() { parent.onMoveUp() }
        @objc func didTapMoveDown() { parent.onMoveDown() }
        @objc func didTapDelete() { parent.onDelete() }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            // Backspace 且文本为空：上报给父视图处理
            if text.isEmpty,
               let current = textView.text,
               current.isEmpty || textView.textColor == UIColor(ColorTokens.textSecondary) {
                parent.onBackspaceWhenEmpty()
                return false
            }
            // 其余情况（包括换行）正常插入
            return true
        }
    }
}
