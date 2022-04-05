//
//  EmulatorController+TouchMouse.swift
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 4/4/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

extension EmulatorController {
    @objc func setupTouchMouseSupport() {
        touchMouseHandler = EmulatorTouchMouseHandler(view: self.view, delegate: self as? EmulatorTouchMouseHandlerDelegate)
    }
}
