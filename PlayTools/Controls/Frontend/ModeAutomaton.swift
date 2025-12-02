//
//  ModeAutomaton.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/17.
//

import Foundation
import UIKit

// This class manages control mode transitions
// This class manages control mode transitions
public class ModeAutomaton {
    static public func onOption() -> Bool {
        if mode == .editor || mode == .textInput {
            return false
        }
        if mode == .off {
            mode.set(.cameraRotate)
        } else if mode == .arbitraryClick && ActionDispatcher.cursorHideNecessary {
            mode.set(.cameraRotate)
        } else if mode == .cameraRotate {
            if PlaySettings.shared.noKMOnInput {
                mode.set(.arbitraryClick)
            } else {
                mode.set(.off)
            }
        }
        // Some people want option key act as touchpad-touchscreen mapper
        return false
    }

    static public func onCmdK() {
        guard settings.keymapping else {
            return
        }
        EditorController.shared.switchMode()
        
        // 当编辑器关闭时 (!editorMode) 且当前处于编辑器模式 (.editor)
        if mode == .editor && !EditorController.shared.editorMode {
            // 不再直接设置模式，而是调用弹窗询问用户
            showCloseEditorAlert()
        } else if EditorController.shared.editorMode {
            mode.set(.editor)
            Toucher.writeLog(logMessage: "editor opened")
        }
    }

    static public func onUITextInputBeginEdit() {
        if mode == .editor {
            return
        }
        mode.set(.textInput)
    }

    static public func onUITextInputEndEdit() {
        if mode == .editor {
            return
        }
        mode.set(.arbitraryClick)
    }
    
    // 新增：显示选择模式的弹窗
    static private func showCloseEditorAlert() {
        // 获取当前的主窗口控制器以显示弹窗
        // 使用 PlayScreen.shared.keyWindow (源自 PlayScreen.swift) [cite: 1104]
        guard let rootVC = PlayScreen.shared.keyWindow?.rootViewController else {
            // 如果找不到窗口，默认回退到原来的逻辑 (CameraRotate)
            restoreToCameraMode()
            return
        }

        let alert = UIAlertController(
            title: "Editor Closed",
            message: "Choose mouse mode:",
            preferredStyle: .alert
        )

        // 选项 1: 恢复原来的逻辑 (视角旋转/FPS模式 - 鼠标隐藏)
        let cameraAction = UIAlertAction(title: "Camera Rotate (FPS)", style: .default) { _ in
            restoreToCameraMode()
        }

        // 选项 2: 显示鼠标 (点按模式 - 鼠标可见)
        let mouseAction = UIAlertAction(title: "Show Mouse (Cursor)", style: .default) { _ in
            mode.set(.arbitraryClick)
            ActionDispatcher.build()
            Toucher.writeLog(logMessage: "editor closed - arbitraryClick selected")
        }

        alert.addAction(cameraAction)
        alert.addAction(mouseAction)

        // 必须在主线程显示 UI
        DispatchQueue.main.async {
            rootVC.present(alert, animated: true, completion: nil)
        }
    }

    // 辅助函数：恢复到原有的 CameraRotate 逻辑
    static private func restoreToCameraMode() {
        mode.set(.cameraRotate)
        ActionDispatcher.build()
        Toucher.writeLog(logMessage: "editor closed - cameraRotate default")
    }
}
