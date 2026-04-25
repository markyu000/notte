//
//  NodeTitleEditor.swift
//  Notte
//
//  Created by 余哲源 on 2026/4/26.
//

import SwiftUI
import UIKit

/// 专用于 Node 标题输入的 UITextField 包装。
/// 单行输入，支持 Return / Backspace 空时 / Tab / Shift+Tab 键盘行为。
struct NodeTitleEditor: UIViewRepresentable {

    var text: String
    var depth: Int
    var onTextChanged: (String) -> Void
    var onReturn: () -> Void
    var onBackspaceWhenEmpty: () -> Void
    var onTab: () -> Void
    var onShiftTab: () -> Void

    func makeUIView(context: Context) -> CustomTextField {
        let field = CustomTextField()
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.font = UIFont.preferredFont(forTextStyle: depth == 0 ? .headline : .body)
        field.placeholder = depth == 0 ? "标题" : "节点"
        field.delegate = context.coordinator
        field.onBackspaceWhenEmpty = { context.coordinator.parent.onBackspaceWhenEmpty() }
        return field
    }

    func updateUIView(_ uiView: CustomTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = UIFont.preferredFont(forTextStyle: depth == 0 ? .headline : .body)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - 自定义 UITextField，拦截 Backspace

    class CustomTextField: UITextField {
        var onBackspaceWhenEmpty: (() -> Void)?

        override func deleteBackward() {
            if text?.isEmpty == true {
                onBackspaceWhenEmpty?()
            } else {
                super.deleteBackward()
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NodeTitleEditor

        init(_ parent: NodeTitleEditor) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.onTextChanged(textField.text ?? "")
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn()
            return false
        }
    }
}
