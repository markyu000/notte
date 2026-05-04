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
/// inputAccessoryView 直接设在 UITextField 上，因为 SwiftUI placement:.keyboard
/// 对 UIViewRepresentable 无效。
struct NodeTitleEditor: UIViewRepresentable {

    var text: String
    var depth: Int
    var isFocused: Bool
    var onTextChanged: (String) -> Void
    var onReturn: () -> Void
    var onBackspaceWhenEmpty: () -> Void
    var onTab: () -> Void
    var onShiftTab: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var onFocus: () -> Void

    func makeUIView(context: Context) -> CustomTextField {
        let field = CustomTextField()
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.font = UIFont.preferredFont(forTextStyle: depth == 0 ? .headline : .body)
        field.placeholder = depth == 0 ? "标题" : "节点"
        field.delegate = context.coordinator
        field.onBackspaceWhenEmpty = { context.coordinator.parent.onBackspaceWhenEmpty() }
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textFieldDidChange(_:)),
            for: .editingChanged
        )
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingDidBegin(_:)),
            for: .editingDidBegin
        )
        field.inputAccessoryView = makeInputAccessoryView(coordinator: context.coordinator)
        return field
    }

    func updateUIView(_ uiView: CustomTextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = UIFont.preferredFont(forTextStyle: depth == 0 ? .headline : .body)
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }

    private func makeInputAccessoryView(coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(
                image: UIImage(systemName: "decrease.indent"),
                style: .plain, target: coordinator,
                action: #selector(Coordinator.didTapOutdent)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "increase.indent"),
                style: .plain, target: coordinator,
                action: #selector(Coordinator.didTapIndent)
            ),
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
            UIBarButtonItem(
                title: "完成", style: .done, target: coordinator,
                action: #selector(Coordinator.didTapDone)
            ),
        ]
        return toolbar
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

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.onTextChanged(textField.text ?? "")
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn()
            return false
        }
        
        @objc func editingDidBegin(_ textField: UITextField) {
            let onFocus = parent.onFocus
            DispatchQueue.main.async {
                onFocus()
            }
        }

        @objc func didTapIndent() { parent.onTab() }
        @objc func didTapOutdent() { parent.onShiftTab() }
        @objc func didTapMoveUp() { parent.onMoveUp() }
        @objc func didTapMoveDown() { parent.onMoveDown() }
        @objc func didTapDone() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}
