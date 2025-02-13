//
//  SwipeButtonsView.swift
//
//
//  Created by MagicianQuinn on 2025/1/13.
//
//

import Foundation
import UIKit

open class SwipeButtonsView: UIView {
    open weak var cell: SwipeTableCell?
    open var backgroundColorCopy: UIColor?

    var buttons: [UIView] = []
    lazy var container: UIView = {
        var container = UIView(frame: bounds)
        container.clipsToBounds = true
        container.backgroundColor = .clear
        return container
    }()

    var fromLeft: Bool = false
    var direction: SwipeDirection = .leftToRight
    var buttonDistance: Double = 0
    var safeInset: Double = 0

    // TODO: expansion

    init(buttons: [UIView], direction: SwipeDirection, swipeSettings: SwipeSettings, safeInset: Double) {
        var containerWidth: Double = 0
        var maxSize = CGSizeZero
        let lastButton = buttons.last

        for button in buttons {
            containerWidth += CGRectGetWidth(button.bounds) + (lastButton == button ? 0 : swipeSettings.buttonsDistance)
            maxSize.width = max(maxSize.width, CGRectGetWidth(button.bounds))
            maxSize.height = max(maxSize.height, CGRectGetHeight(button.bounds))
        }
        if !swipeSettings.allowsButtonsWithDifferentWidth {
            let sumWidth: Double = maxSize.width * Double(buttons.count)
            let spacings = swipeSettings.buttonsDistance * Double(buttons.count - 1)
            containerWidth = sumWidth + spacings
        }
        super.init(frame: CGRectMake(0, 0, containerWidth + safeInset, maxSize.height))

        fromLeft = direction == .leftToRight
        buttonDistance = swipeSettings.buttonsDistance
        self.direction = direction
        self.safeInset = safeInset

        addSubview(container)

        if fromLeft {
            self.buttons = buttons
        } else {
            self.buttons = buttons.reversed()
        }

        for button in buttons {
            if button.isKind(of: UIButton.self) {
                let btn = button as! UIButton
                btn.removeTarget(nil, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
                btn.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
            }
            if !swipeSettings.allowsButtonsWithDifferentWidth {
                button.frame = CGRectMake(0, 0, maxSize.width, maxSize.height)
            }
            button.autoresizingMask = .flexibleHeight

            container.insertSubview(button, at: fromLeft ? 0 : container.subviews.count)
        }

        if safeInset > 0 && swipeSettings.expanLastButtonBySafeAreaInsets && !buttons.isEmpty {
            var notchButton = self.direction == .rightToLeft ? buttons.last : buttons.first
            if let notchBtn = notchButton {
                notchBtn.frame = CGRectMake(0, 0, CGRectGetWidth(notchBtn.frame) + safeInset, CGRectGetHeight(notchBtn.frame))
                adjustContentEdge(button: notchBtn, edgeDelta: safeInset)
            }
        }

        resetButtons()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for button in self.buttons {
            if button.isKind(of: UIButton.self) {
                let btn = button as! UIButton
                btn.removeTarget(nil, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
            }
        }
    }

    func resetButtons() {
        var offsetX: Double = 0
        let lastBtn = buttons.last
        for btn in buttons {
            btn.frame = CGRectMake(offsetX, 0, CGRectGetWidth(btn.bounds), CGRectGetHeight(bounds))
            btn.autoresizingMask = .flexibleHeight
            offsetX += CGRectGetWidth(btn.bounds) + (lastBtn == btn ? 0 : buttonDistance)
        }
    }

    func setSafeInsetAndExtendEdgeButton(safeInset: Double, extended: Bool, isRTL: Bool) {
        let diff = safeInset - self.safeInset
        if diff != 0 {
            self.safeInset = safeInset
            if extended {
                var edgeButton = direction == .rightToLeft ? buttons.last : buttons.first
                if let edgeBtn = edgeButton {
                    edgeBtn.frame = CGRectMake(0, 0, CGRectGetWidth(edgeBtn.bounds) + diff, CGRectGetHeight(edgeBtn.frame))
                    // Adjust last button content edge (to correctly align the text/icon)
                    adjustContentEdge(button: edgeBtn, edgeDelta: diff)
                }
            }

            var frame = self.frame
            let transform = self.transform
            self.transform = CGAffineTransformIdentity

            frame.size.width += diff
            if direction == .leftToRight {
                frame.origin.x = -CGRectGetWidth(frame) + safeInset * (isRTL ? 1 : -1)
            } else {
                if let superBounds = superview?.bounds {
                    frame.origin.x = CGRectGetWidth(superBounds) + safeInset * (isRTL ? 1 : -1)
                }
            }

            self.frame = frame
            self.transform = transform
            resetButtons()
        }
    }

    @objc func buttonClicked(sender: UIButton) {
        let _ = handleClick(sender: sender, from: false)
    }

    func handleClick(sender: UIView, from _: Bool) -> Bool {
        var autoHide = false
        guard let cell = cell else { return autoHide }
        if sender.isKind(of: SwipeButton.self), let btn = sender as? SwipeButton, let callback = btn.callSwipeConvenienceCallback {
            autoHide = callback(cell)
        }

        let index = buttons.firstIndex { button in
            button == sender
        }
        if let index = index {
            var idx = index
            if !fromLeft {
                idx = buttons.count - idx - 1 // right buttons are reversed.
            }
            let curDirection: SwipeDirection = fromLeft ? .leftToRight : .rightToLeft
            if let result = cell.swipeDelegate?.swipeTableCell(cell, tappedButtonAt: idx, direction: curDirection) {
                autoHide = autoHide || result
            }
        }
        if autoHide {
            cell.hideSwipe(animated: true)
        }

        return autoHide
    }

    func adjustContentEdge(button: UIView, edgeDelta: Double) {
        if button.isKind(of: UIButton.self) {
            let btn = button as! UIButton
            var contentInsets = btn.contentEdgeInsets
            if direction == .rightToLeft {
                contentInsets.right += edgeDelta
            } else {
                contentInsets.left += edgeDelta
            }
            btn.contentEdgeInsets = contentInsets
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        container.frame = bounds
    }

    // MARK: Transtions

    public func transtion(mode: SwipeTransition, t: Double) {
        switch mode {
        case .drag:
            transitionDrag(percent: t)
        case .static:
            transitionStatic(percent: t)
        case .border:
            transitionBorder(percent: t)
        }
    }

    func transitionStatic(percent t: Double) {
        let dx: Double = CGRectGetWidth(bounds) * (1.0 - t)
        var offsetX: Double = 0

        let last = buttons.last
        for button in buttons {
            var frame = button.frame
            frame.origin.x = offsetX + (fromLeft ? dx : -dx)
            button.frame = frame
            offsetX += frame.size.width + (button == last ? 0 : buttonDistance)
        }
    }

    func transitionDrag(percent _: Double) {}

    func transitionBorder(percent t: Double) {
        let width = CGRectGetWidth(bounds)
        var offsetX: Double = 0

        let lastButton = buttons.last
        for button in buttons {
            var frame = button.frame
            frame.origin.x = fromLeft ? (width - CGRectGetWidth(frame) - offsetX) * (1.0 - t) + offsetX : offsetX * t
            button.frame = frame
            offsetX += CGRectGetWidth(frame) + (button == lastButton ? 0 : buttonDistance)
        }
    }
}
