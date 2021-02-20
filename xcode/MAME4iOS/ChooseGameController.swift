//
//  ChooseGameController.swift
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/20.
//
import UIKit

#if canImport(WidgetKit)
import WidgetKit

extension UIApplication {
    // you can only call WidgetCenter::reloadAllTimelines from Swift, so make a ObjC callable thunk.
    @objc public static func reloadAllWidgets() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
#endif


