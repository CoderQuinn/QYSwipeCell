//
//  SwipeButton.swift
//  Dola
//
//  Created by MagicianQuinn on 2025/1/9.
//  Copyright © 2025 Orion Arm Pte. Ltd. All rights reserved.
//

import Foundation
import UIKit

public typealias SwipeButtonCallback = (SwipeTableCell) -> Bool
/**
 * This is a convenience class to create MGSwipeTableCell buttons
 * Using this class is optional because MGSwipeTableCell is button agnostic and can use any UIView for that purpose
 * Anyway, it's recommended that you use this class because is totally tested and easy to use ;)
 */
open class SwipeButton: UIButton {
    open var callSwipeConvenienceCallback: SwipeButtonCallback?

    /** A width for the expanded buttons. Defaults to 0, which means sizeToFit will be called. */
    open var buttonWidth: Double = 0.0

    /**
     * Convenience static constructors
     */
    public convenience init(title: String, icon: UIImage?, backgroundColor color: UIColor?, insets: UIEdgeInsets, callback: SwipeButtonCallback? = nil) {
        self.init(frame: .zero)
        
        backgroundColor = color
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
        setTitle(title, for: .normal)
        setTitleColor(UIColor.white, for: .normal)
        setImage(icon, for: .normal)
        self.callSwipeConvenienceCallback = callback
        setEdgeInsets(insets)
    }

    open func setPadding(_: CGFloat) {}

    open func setEdgeInsets(_: UIEdgeInsets) {}

    open func centerIconOverText() {}

    open func centerIconOverText(withSpacing _: CGFloat) {}

    open func iconTintColor(_: UIColor?) {}
}
