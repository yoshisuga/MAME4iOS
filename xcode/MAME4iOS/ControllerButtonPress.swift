//
//  File.swift
//  MAME4iOS
//
//  Created by Todd Laney on 2/14/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation
import UIKit

@objc enum ButtonPressType: Int {
    case none = -1
    case up,down,left,right // *HACK* These must match UIPress.PressType
    case select, back       // *HACK* These must match UIPress.PressType
    case menu, options, home
}

// MARK: - handleButtonPress - UINavigationController

extension UINavigationController {
    
    @objc func handleButtonPress(_ type: ButtonPressType) {
        switch type {
        case .back:
             // if there is a BACK button, press it
            if self.navigationBar.backItem != nil {
                self.popViewController(animated: true)
            }
            // if there is a DONE button, press it
            else if let bbi = self.navigationBar.topItem?.rightBarButtonItem {
                if bbi.style == .done || bbi.action == NSSelectorFromString("done:") {
                    _ = bbi.target?.perform(bbi.action, with:bbi)
                }
            }
        default:
            break
        }
    }
}

// MARK: - handleButtonPress - UITableViewController

extension UITableViewController {
    
    @objc func handleButtonPress(_ type: ButtonPressType) {
        switch type {
        case .select:
            if let indexPath = tableView.indexPathForSelectedRow {
                clearsSelectionOnViewWillAppear = false
                tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
                
                if let cell = tableView.cellForRow(at: indexPath) {
                    if cell.accessoryType != .none {
                        tableView.delegate?.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
                    }
                    if let sw = cell.accessoryView as? UISwitch {
                        sw.isOn = !sw.isOn
                        sw.sendActions(for: .valueChanged)
                    }
                }
            }
        case .up:
            moveSelection(-1)
        case .down:
            moveSelection(+1)
        default:
            break
        }
    }
    private func maxSection() -> Int {
        return tableView.numberOfSections-1
    }
    private func maxRow(_ indexPath:IndexPath) -> Int {
        return tableView.numberOfRows(inSection:indexPath.section)-1
    }
    private func select(_ indexPath:IndexPath) {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView.scrollToRow(at: indexPath, at: .none, animated: false)
    }
    private func moveSelection(_ dir:Int) {
        guard var indexPath = tableView.indexPathForSelectedRow else {
            return select(IndexPath(row:0, section:0))
        }
        if dir == -1 && indexPath.row == 0 && indexPath.section != 0 {
            indexPath.section -= 1
            indexPath.row = maxRow(indexPath)
        }
        else if dir == +1 && indexPath.row == maxRow(indexPath) && indexPath.section < maxSection() {
            indexPath.section += 1
            indexPath.row = 0
        }
        else {
            indexPath.row += dir
            indexPath.row = max(0, min(indexPath.row, maxRow(indexPath)))
        }

        // skip over section with zero items
        while maxRow(indexPath) == -1 {
            indexPath.section += dir
            indexPath.row = dir == +1 ? 0 : maxRow(indexPath)
            if indexPath.section < 0 || indexPath.section > maxSection() {
                return
            }
        }
        
        select(indexPath)
    }
}

/*
extension UIAlertController {
    @objc func handleButtonPress(_ type: UIPress.PressType) {
        switch type {
        case .select:   // (aka A or ENTER)
            dismiss(with: preferredAction, animated: true)
        case .menu:     // (aka B or ESC)
            let cancelAction = actions.first(where: {$0.style == .cancel})
            dismiss(with: cancelAction, animated: true)
        default:
            break
        }
    }
    private func dismiss(with action:UIAlertAction?, animated: Bool) {
        if let action = action {
            presentingViewController?.dismiss(animated: animated, completion: {
                action.callActionHandler()
            })
        }
    }
}
*/




