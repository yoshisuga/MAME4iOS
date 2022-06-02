//
//  Collection+Safe.swift
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 5/31/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
