//
//  SwipeSettings.swift
//  Dola
//
//  Created by MagicianQuinn on 2025/1/9.
//  Copyright © 2025 Orion Arm Pte. Ltd. All rights reserved.
//

public class SwipeSettings {
    /** Transition used while swiping buttons */
    public var transition: SwipeTransition = .drag

    /** Size proportional threshold to hide/keep the buttons when the user ends swiping. Default value 0.5 */
    public var threshold: Double = 0.5

    /** Optional offset to change the swipe buttons position. Relative to the cell border position. Default value: 0
     ** For example it can be used to avoid cropped buttons when sectionIndexTitlesForTableView is used in the UITableView
     **/
    public var offset: Double = 0

    /** Top margin of the buttons relative to the contentView */
    public var topMargin: Double = 0

    /** Bottom margin of the buttons relative to the contentView */
    public var bottomMargin: Double = 0

    /** Distance between the buttons. Default value : 0 */
    public var buttonsDistance: Double = 0

    /** If true, expands the last button length by safeAreaInsets. Useful for devices with a notch (e.g. iPhone X) */
    public var expanLastButtonBySafeAreaInsets: Bool = true

    /** Animation settings when the swipe buttons are shown */
    var showAnimation = SwipeAnimation()

    /** Animation settings when the swipe buttons are hided */
    var hideAnimation = SwipeAnimation()

    /** Animation settings when the cell is stretched from the swipe buttons */
    var stretchAnimation = SwipeAnimation()

    /** If true the buttons are kept swiped when the threshold is reached and the user ends the gesture
     * If false, the buttons are always hidden when the user ends the swipe gesture
     */
    public var keepButtonsSwiped: Bool = true

    /** If true the table cell is not swiped, just the buttons **/
    public var onlySwipeButtons: Bool = false

    /** If NO the swipe bounces will be disabled, the swipe motion will stop right after the button */
    public var enableSwipeBounces: Bool = true

    /** Coefficient applied to cell movement in bounce zone. Set to value between 0.0 and 1.0
     to make the cell 'resist' swiping after buttons are revealed. Default is 1.0 */
    public var swipeBounceRate: Double = 1.0

    public var allowsButtonsWithDifferentWidth: Bool = false
}
