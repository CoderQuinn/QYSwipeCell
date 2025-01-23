//
//  SwipeTableCellDelegate.swift
// 
//
//  Created by MagicianQuinn on 2025/1/10.
// 
//

import UIKit

public protocol SwipeTableCellDelegate: AnyObject {
    func swipeTableCell(_ cell: SwipeTableCell, canSwipe direction: SwipeDirection, from point: CGPoint) -> Bool

    func swipeTableCell(_ cell: SwipeTableCell, didChange state: SwipeState, gestureIsActive: Bool)

    func swipeTableCell(_ cell: SwipeTableCell, tappedButtonAt index: Int, direction: SwipeDirection) -> Bool

    func swipeTableCell(_ cell: SwipeTableCell, swipeButtonsFor direction: SwipeDirection, swipeSettings: SwipeSettings?) -> [UIView]?

    func swipeTableCell(_ cell: SwipeTableCell, shouldHideSwipeOnTap point: CGPoint) -> Bool

    func swipeTableCellWillBeginSwiping(_ cell: SwipeTableCell)

    func swipeTableCellWillEndSwiping(_ cell: SwipeTableCell)
}
