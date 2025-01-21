//
//  SwipeButton.swift
//
//
//  Created by MagicianQuinn on 2025/1/9.
//

import Foundation
import UIKit

typealias SwipeButtonCallback = (SwipeTableCell) -> Bool

class SwipeButton: UIButton {
    var callback: SwipeButtonCallback?
    // TODO:
    public func callSwipeConvenienceCallback(cell: SwipeTableCell) -> Bool {
        guard let callback = callback else {
            return false
        }
        return callback(cell)
    }
}
