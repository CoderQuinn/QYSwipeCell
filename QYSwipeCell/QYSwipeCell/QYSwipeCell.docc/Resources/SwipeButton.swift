//
//  SwipeButton.swift
// 
//
//  Created by MagicianQuinn on 2025/1/9.
// 
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
        callSwipeConvenienceCallback = callback
        setEdgeInsets(insets: insets)
    }

    open func setPadding(padding: CGFloat) {
        contentEdgeInsets = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
        sizeToFit()
    }

    open func setEdgeInsets(insets: UIEdgeInsets) {
        contentEdgeInsets = insets
        sizeToFit()
    }

    open func centerIconOverText() {
        centerIconOverText(withSpacing: 3.0)
    }

    open func centerIconOverText(withSpacing _: CGFloat) {}

    open func iconTintColor(tintColor: UIColor?) {
        var currentIcon = imageView?.image
        if currentIcon?.renderingMode != .alwaysTemplate {
            currentIcon = currentIcon?.withRenderingMode(.alwaysTemplate)
            setImage(currentImage, for: .normal)
        }
        self.tintColor = tintColor
    }
    
    func isRTLLocal() -> Bool {
        if #available(iOS 9.0, *) {
            return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        } else if isAppExtension() {
            return Locale.characterDirection(forLanguage: Locale.current.languageCode!) == .rightToLeft
        } else {
            return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        }
    }
    
    func isAppExtension() -> Bool {
        guard let path = Bundle.main.executablePath else { return false }
        return path.range(of: ".appex/") != nil
    }
}
