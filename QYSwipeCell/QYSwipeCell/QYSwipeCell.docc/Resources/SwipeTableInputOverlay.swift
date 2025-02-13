//
//  SwipeTableInputOverlay.swift
//
//
//  Created by MagicianQuinn on 2025/1/13.
//
//

import UIKit

class SwipeTableInputOverlay: UIView {
    weak var currentCell: SwipeTableCell?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let event = event else {
            return nil
        }

        guard let currentCell = currentCell else {
            removeFromSuperview()
            return nil
        }

        let p = convert(point, to: currentCell)
        if currentCell.isHidden || CGRectContainsPoint(currentCell.bounds, p) {
            return nil
        }

        if let hide = currentCell.swipeDelegate?.swipeTableCell(currentCell, shouldHideSwipeOnTap: p) {
            if hide {
                currentCell.hideSwipe(animated: true)
            }
        }
        return currentCell.touchOnDismissSwipe ? nil : self
    }
}
