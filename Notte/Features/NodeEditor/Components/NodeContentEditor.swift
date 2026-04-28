//
//  NodeContentEditor.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/25.
//

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
