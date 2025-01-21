//
//  SwipeTableCell.swift
//
//
//  Created by MagicianQuinn on 2025/1/10.
//
//
import Foundation
import UIKit

/**
 * Swipe Cell class
 * To implement swipe cells you have to override from this class
 * You can create the cells programmatically, using xibs or storyboards
 */
public class SwipeTableCell: UITableViewCell {
    typealias AnimationCompletion = (Bool) -> Void

    public weak var swipeDelegate: SwipeTableCellDelegate?

    public var leftViews: [UIView]?
    public var rightViews: [UIView]?
    public var leftSwipeSettings: SwipeSettings?
    public var rightSwipeSettings: SwipeSettings?

    /** fetch the current swipe state */
    public internal(set) var swipeState: SwipeState = .none

    // default is NO. Controls whether multiple cells can be swiped simultaneously
    public var allowsMultipleSwipe: Bool = false
    // default is YES. Controls whether swipe gesture is allowed when the touch starts into the swiped buttons
    public var allowsSwipeWhenTappingUiews: Bool = false
    // default is YES. Controls whether swipe gesture is allowed in opposite directions. NO value disables swiping in opposite direction once started in one direction
    public var allowsOppositeSwipe: Bool = false
    // default is NO.  Controls whether the cell selection/highlight status is preserved when expansion occurs
    public var preservesSelectionStatus: Bool = true
    /* default is NO. Controls whether dismissing a swiped cell when tapping outside of the cell generates a real touch event on the other cell.
     Default behaviour is the same as the Mail app on iOS. Enable it if you want to allow to start a new swipe while a cell is already in swiped in a single step.  */
    public var touchOnDismissSwipe: Bool = false
    /** Optional background color for swipe overlay. If not set, its inferred automatically from the cell contentView */
    public var swipeBackgroundColor: UIColor?
    /** Property to read or change the current swipe offset programmatically */
    public var swipeOffset: Double = 0

    // MARK: Private

    var tapRecognizer: UITapGestureRecognizer?
    var panRecognizer: UIPanGestureRecognizer?
    var panStartPoint: CGPoint = .zero
    var panStartOffset: Double = 0
    var targetOffset: Double = 0

    var swipeOverlay: UIView?
    var swipeView: UIImageView?
    /** optional to use contentView alternative. Use this property instead of contentView to support animated views while swiping */
    public internal(set) lazy var swipeContentView: UIView? = {
        var view = UIView(frame: contentView.bounds)
        view.backgroundColor = .clear
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.layer.zPosition = 9.0
        return view
    }()

    var leftView: SwipeButtonsView?
    var rightView: SwipeButtonsView?
    var allowSwipeRightToLeft: Bool = false
    var allowSwipeLeftToRight: Bool = false

    var tableInputOverlay: SwipeTableInputOverlay?
    var overlayEnabled: Bool = false
    var previusSelectionStyle: UITableViewCell.SelectionStyle = .none
    var previusHiddenViews: Set<UIView> = .init()
    var previusAccessoryType: UITableViewCell.AccessoryType = .none
    var triggerStateChanges: Bool = false

    var animatinonData: SwipeAnimationData?
    var animationCompletion: AnimationCompletion?
    var displayLink: CADisplayLink?
    var firstSwipeState: SwipeState = .none

    // MARK: Initization

    deinit {
        hideSwipeOverlayIfNeeded(including: false)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews(cleanViews: true)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initViews(cleanViews: true)
    }

    // MARK: Override

    override public func awakeFromNib() {
        super.awakeFromNib()
        if panRecognizer == nil {
            initViews(cleanViews: true)
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        if let swipeContentView = swipeContentView {
            contentView.addSubview(swipeContentView)
            swipeContentView.frame = contentView.bounds
        }

        guard let swipeoverlay = swipeOverlay else { return }
        guard let swipeView = swipeView else { return }

        let prevSize = swipeView.bounds.size
        swipeoverlay.frame = CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds))
        fixRegionAndAccesoryViews()
        if swipeView.image != nil && !CGSizeEqualToSize(prevSize, swipeoverlay.bounds.size) {
            let safeInsets = getSafeInsets()
            if let leftView = leftView {
                let width = CGRectGetWidth(leftView.bounds)
                var extended = false
                if let leftSwipeSettings = leftSwipeSettings {
                    extended = leftSwipeSettings.expanLastButtonBySafeAreaInsets
                }
                leftView.setSafeInsetAndExtendEdgeButton(safeInset: safeInsets.left, extended: extended, isRTL: isRTLLocal())
                if swipeOffset > 0 && CGRectGetWidth(leftView.bounds) != width {
                    swipeOffset += CGRectGetWidth(leftView.bounds) - width
                }
            }

            if let rightView = rightView {
                let width = CGRectGetWidth(rightView.bounds)
                var extended = false
                if let rightSwipeSettings = rightSwipeSettings {
                    extended = rightSwipeSettings.expanLastButtonBySafeAreaInsets
                }
                rightView.setSafeInsetAndExtendEdgeButton(safeInset: safeInsets.right, extended: extended, isRTL: isRTLLocal())
                if swipeOffset < 0 && CGRectGetWidth(rightView.bounds) != width {
                    swipeOffset -= -CGRectGetWidth(rightView.bounds) - width
                }
            }

            refreshContentView()
        }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        guard let _ = newSuperview else {
            hideSwipeOverlayIfNeeded(including: false)
            return
        }
        super.willMove(toSuperview: newSuperview)
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        cleanViews()
        if swipeState != .none {
            triggerStateChanges = true
            updateState(newState: .none)
        }

        let cleanViews = swipeDelegate?.swipeTableCell(self, swipeButtonsFor: .rightToLeft, swipeSettings: rightSwipeSettings)
        let clean = cleanViews != nil
        initViews(cleanViews: clean)
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            swipeOffset = 0
        }
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let targetView = rightView, !isHidden && swipeOverlay != nil && !(swipeOverlay!.isHidden) {
            let p = convert(point, to: targetView)
            if CGRectContainsPoint(targetView.bounds, p) {
                return targetView.hitTest(p, with: event)
            }
        }

        return super.hitTest(point, with: event)
    }

    // MARK: Private

    func initViews(cleanViews: Bool) {
        if cleanViews {
            leftViews = [UIView]()
            rightViews = [UIView]()
            leftSwipeSettings = SwipeSettings()
            rightSwipeSettings = SwipeSettings()
        }

        animatinonData = SwipeAnimationData()
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panHandler(gesture:)))
        addGestureRecognizer(panRecognizer!)
        panRecognizer?.delegate = self
        previusHiddenViews = Set<UIView>()
        swipeState = .none
        triggerStateChanges = true
        allowsSwipeWhenTappingUiews = true
        preservesSelectionStatus = false
        allowsOppositeSwipe = true
        firstSwipeState = .none
    }

    func cleanViews() {
        hideSwipe(animated: false)
        if let displayLink = displayLink {
            displayLink.invalidate()
        }
        displayLink = nil

        if let swipeOverlay = swipeOverlay {
            swipeOverlay.removeFromSuperview()
        }
        swipeOverlay = nil

        leftView = nil
        rightView = nil
        if let panRecognizer = panRecognizer {
            panRecognizer.delegate = nil
            removeGestureRecognizer(panRecognizer)
        }
        panRecognizer = nil
    }

    func isAppExtension() -> Bool {
        guard let path = Bundle.main.executablePath else { return false }
        return path.range(of: ".appex/") != nil
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

    // Fix right to left layout direction for arabic and hebrew languagues
    func fixRegionAndAccesoryViews() {
        guard let swipeOverlay = swipeOverlay else { return }
        if CGRectGetWidth(bounds) != CGRectGetWidth(contentView.bounds) && isRTLLocal() {
            swipeOverlay.frame = CGRectMake(-CGRectGetWidth(bounds) + CGRectGetWidth(contentView.bounds), 0, CGRectGetWidth(swipeOverlay.bounds), CGRectGetHeight(swipeOverlay.bounds))
        }
    }

    func getSafeInsets() -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return safeAreaInsets
        } else {
            return UIEdgeInsets.zero
        }
    }

    func fetchButtonsIfNeed() {
        if leftViews?.isEmpty == true {
            leftViews = swipeDelegate?.swipeTableCell(self, swipeButtonsFor: .leftToRight, swipeSettings: leftSwipeSettings)
        }

        if rightViews?.isEmpty == true {
            rightViews = swipeDelegate?.swipeTableCell(self, swipeButtonsFor: .rightToLeft, swipeSettings: rightSwipeSettings)
        }
    }

    func createSwipeViewIfNeeded() {
        let safeInset = getSafeInsets()

        if swipeOverlay == nil {
            swipeOverlay = UIView(frame: CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds)))
            fixRegionAndAccesoryViews()
            swipeOverlay!.isHidden = true
            swipeOverlay!.backgroundColor = backgroundColorForSwipe()
            swipeOverlay!.layer.zPosition = 10.0

            swipeView = UIImageView(frame: swipeOverlay!.bounds)
            swipeView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            swipeView!.contentMode = .center
            swipeView!.clipsToBounds = true
            swipeOverlay!.addSubview(swipeView!)
            contentView.addSubview(swipeOverlay!)
        }
        fetchButtonsIfNeed()

        if let leftViews = leftViews, let leftSwipeSettings = leftSwipeSettings, leftView == nil && !leftViews.isEmpty {
            leftView = SwipeButtonsView(buttons: leftViews, direction: SwipeDirection.leftToRight, swipeSettings: leftSwipeSettings, safeInset: safeInset.left)
            leftView!.cell = self
            leftView!.frame = CGRectMake(-CGRectGetWidth(leftView) + safeInset.left * (isRTLLocal() ? 1 : -1), leftSwipeSettings?.topMargin, CGRectGetWidth(leftView?.buttons), CGRectGetHeight(swipeOverlay) - leftSwipeSettings?.topMargin - leftSwipeSettings?.bottomMargin)
            leftView!.autoresizingMask = [.flexibleRightMargin, .flexibleHeight]
            swipeOverlay?.addSubview(leftView!)
        }

        if rightView == nil && !rightViews.isEmpty {
            rightView = SwipeButtonsView(buttons: rightViews, direction: SwipeDirection.rightToLeft, swipeSettings: rightSwipeSettings, safeInset: safeInset.right)
            rightView?.cell = self
            rightView?.frame = CGRectMake(CGRectGetWidth(swipeOverlay?.bounds) + safeInset.right * (isRTLLocal() ? 1 : -1), rightSwipeSettings?.topMargin, CGRectGetWidth(rightView?.bounds), CGRectGetHeight(swipeOverlay) - rightSwipeSettings?.topMargin - rightSwipeSettings?.bottomMargin)
            rightView?.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
            swipeOverlay?.addSubview(rightView)
        }
    }

    func showSwipeOverlayIfNeeded() {
        if overlayEnabled {
            return
        }
        overlayEnabled = true

        if !preservesSelectionStatus {
            isSelected = false
        }

        swipeDelegate?.swipeTableCellWillBeginSwiping(self)
        swipeOverlay?.isHidden = false
        if let swipeContentView = swipeContentView {
            swipeContentView.removeFromSuperview()
            swipeView?.image = nil
            swipeView?.addSubview(swipeContentView)
        } else {
            let cropSize = CGSizeMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds))
            swipeView?.image = makeImage(from: self, cropSize: cropSize)
        }

        if !allowsMultipleSwipe, let table = parentTableView() {
            tableInputOverlay?.removeFromSuperview()
            tableInputOverlay = SwipeTableInputOverlay(frame: table.bounds)
            tableInputOverlay?.currentCell = self
            table.addSubview(tableInputOverlay!)
        }

        previusSelectionStyle = selectionStyle
        selectionStyle = .none
        setAccessoryView(hidden: true)

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler(gesture:)))
        tapRecognizer?.cancelsTouchesInView = true
        tapRecognizer?.delegate = self
        addGestureRecognizer(tapRecognizer!)
    }

    func hideSwipeOverlayIfNeeded(including reselect: Bool) {
        if !overlayEnabled {
            return
        }
        overlayEnabled = false
        swipeOverlay?.isHidden = true
        swipeView?.image = nil

        if let swipeContentView = swipeContentView {
            swipeContentView.removeFromSuperview()
            contentView.addSubview(swipeContentView)
        }

        if let tableInputOverlay = tableInputOverlay {
            tableInputOverlay.removeFromSuperview()
        }
        tableInputOverlay = nil

        if reselect {
            selectionStyle = previusSelectionStyle
            if let parentTable = parentTableView() {
                let rows = parentTable.indexPathsForSelectedRows
                if (rows?.contains(where: { idx in
                    idx == parentTable.indexPath(for: self)
                })) != nil {
                    isSelected = false // Hack: in some iOS versions setting the selected property to YES own isn't enough to force the cell to redraw the chosen selectionStyle
                    isSelected = true
                }
            }
        }
        setAccessoryView(hidden: false)
        swipeDelegate?.swipeTableCellWillEndSwiping(self)

        if let tapRecognizer = tapRecognizer {
            removeGestureRecognizer(tapRecognizer)
        }
        tapRecognizer = nil
    }

    func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        if let completion = animationCompletion {
            animationCompletion = nil
            completion(true)
        }
    }

    // MARK: Utility

    func makeImage(from view: UIView, cropSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: cropSize)
        let image = renderer.image(actions: { renderContext in
            view.layer.render(in: renderContext.cgContext)
        })
        return image
    }

    func setAccessoryView(hidden: Bool) {
        if #available(iOS 12, *) {
            if hidden {
                previusAccessoryType = accessoryType
                accessoryType = .none
            } else if accessoryType == .none {
                accessoryType = previusAccessoryType
                previusAccessoryType = .none
            }
        }

        accessoryView?.isHidden = hidden

        if let superView = contentView.superview {
            for view in superView.subviews {
                if view == contentView {
                    continue
                }

                if view.isKind(of: UIButton.self) || NSStringFromClass(view.classForCoder).contains("Disclosure") {
                    view.isHidden = hidden
                }
            }
        }

        for view in contentView.subviews {
            if view == swipeOverlay || view == swipeContentView {
                continue
            }

            if hidden && !view.isHidden {
                view.isHidden = true
                previusHiddenViews.insert(view)
            } else if !hidden && previusHiddenViews.contains(view) {
                view.isHidden = false
            }
        }

        if !hidden {
            previusHiddenViews.removeAll()
        }
    }

    func backgroundColorForSwipe() -> UIColor {
        if let bgColor = swipeBackgroundColor {
            return bgColor
        }
        if let contentBgColor = contentView.backgroundColor, contentBgColor != .clear {
            return contentBgColor
        }
        guard let bgColor = backgroundColor else {
            return UIColor.clear
        }
        return bgColor
    }

    func parentTableView() -> UITableView? {
        var view = superview
        while view != nil {
            if let t = view, t.isKind(of: UITableView.self) {
                return view as? UITableView
            }
            view = view?.superview
        }
        return nil
    }

    func updateState(newState: SwipeState) {
        if !triggerStateChanges || swipeState == newState {
            return
        }

        swipeState = newState
        swipeDelegate?.swipeTableCell(self, didChange: swipeState, gestureIsActive: isSwipeGestureActive)
    }

    // MARK: Swipe Animation

    func setSwipe(offset newOffset: Double) {
        let sign: Double = newOffset > 0 ? 1.0 : -1.0
        let activeViews = sign < 0 ? rightView : leftView
        let activeSettings: SwipeSettings = sign < 0 ? rightSwipeSettings : leftSwipeSettings

        if activeSettings.enableSwipeBounces {
            swipeOffset = newOffset
            let maxUnbounceOffset = sign * CGRectGetWidth(activeViews?.bounds)
            if (sign > 0 && newOffset > maxUnbounceOffset) || (sign < 0 && newOffset < maxUnbounceOffset) {
                swipeOffset = maxUnbounceOffset + (newOffset - maxUnbounceOffset) * activeSettings.swipeBounceRate
            }
        } else {
            let maxOffset = sign * CGRectGetWidth(activeViews?.buttons)
            swipeOffset = sign > 0 ? min(newOffset, maxOffset) : max(newOffset, maxOffset)
        }
        let offset = fabs(swipeOffset)

        if !activeViews || offset == 0 {
            hideSwipeOverlayIfNeeded(including: true)
            targetOffset = 0
            updateState(newState: .none)

            return
        } else {
            showSwipeOverlayIfNeeded()
            let swipeThreshold = activeSettings.threshold
            let keepViews = activeSettings.keepButtonsSwiped
            targetOffset = keepViews && offset > CGRectGetWidth(activeViews?.bounds) * swipeThreshold ? CGRectGetWidth(activeViews?.bounds) * sign : 0
        }

        let onlyViews = activeSettings.onlySwipeButtons
        let safeInsets = getSafeInsets()
        let safeInset = isRTLLocal() ? safeInsets.right : -safeInsets.left
        swipeView?.transform = CGAffineTransformMakeTranslation(safeInset + (onlyViews ? 0 : swipeOffset), 0)

        let views: [SwipeButtonsView] = [leftView, rightView]
        let settings: [SwipeSettings] = [leftSwipeSettings, rightSwipeSettings]

        for Int i = 0; i < 2; ++i {
            let view = views[i]
            if view == nil {
                continue
            }

            // buttons view position
            let translation = min(offset, CGRectGetWidth(view.bounds)) * sign + settings[i].offset * sign
            view.transform = CGAffineTransformMakeTranslation(translation, 0)

            if view != activeViews { // only transition if active (perf.improvement)
                continue
            }

            var expand = false // TODO: support expand
            if expand {
            } else {
                let t: Double = min(1.0, offset / CGRectGetWidth(view.bounds))
                view.transtion(mode: settings[i].transition, t: t)
                let state = i ? SwipeState.swipingLeftToRight : SwipeState.swipingRightToLeft
                updateState(newState: state)
            }
        }
    }

    public func hideSwipe(animated: Bool) {
        hideSwipe(animated: animated, completion: nil)
    }

    public func hideSwipe(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let animation = animated ? (swipeOffset > 0 ? leftSwipeSettings?.hideAnimation : rightSwipeSettings?.hideAnimation) : nil
        setSwipeOffset(0, animation: animation, completion: completion)
    }

    public func showSwipe(direction: SwipeDirection, animated: Bool) {
        showSwipe(direction: direction, animated: animated, completion: nil)
    }

    public func showSwipe(direction: SwipeDirection, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        createSwipeViewIfNeeded()
        allowSwipeLeftToRight = leftViews?.count > 0
        allowSwipeRightToLeft = rightViews?.count > 0

        let view = direction == SwipeDirection.leftToRight ? leftView : rightView
        if let view = view {
            let s = direction == .leftToRight ? 1.0 : -1.0
            let animation = animated ? (direction == .leftToRight ? leftSwipeSettings?.showAnimation : rightSwipeSettings?.showAnimation) : nil
            setSwipeOffset(CGRectGetWidth(view.bounds) * s, animation: animation, completion: completion)
        }
    }

    public func setSwipeOffset(_ offset: CGFloat, _ animated: Bool, _ completion: ((Bool) -> Void)? = nil) {
        let animation = animated ? SwipeAnimation() : nil
        setSwipeOffset(offset, animation: animation, completion: completion)
    }

    public func setSwipeOffset(_ offset: CGFloat, _ animation: SwipeAnimation?, _ completion: ((Bool) -> Void)? = nil) {
        if displayLink {
            displayLink?.invalidate()
            displayLink = nil
        }

        if let completion = animationCompletion { // notify previous animation cancelled
            animationCompletion = nil
            completion(false)
        }

        if offset != 0 {
            createSwipeViewIfNeeded()
        }

        if !animation {
            swipeOffset = offset
            if completion {
                completion(true)
            }
            return
        }

        animationCompletion = completion
        triggerStateChanges = false
        animatinonData?.from = swipeOffset
        animatinonData?.to = offset
        animatinonData?.duration = animation?.duration
        animatinonData?.start = 0
        animatinonData?.animation = animation
        displayLink = CADisplayLink(target: self, selector: #selector(animationTick:))
        displayLink?.add(to: .main, for: .common)
    }

    // MARK: Public

    /** Refresh method to be used when you want to update the cell contents while the user is swiping */
    public func refreshContentView() {
        let currentOffset = swipeOffset
        let prevValue = triggerStateChanges
        triggerStateChanges = false
        swipeOffset = 0
        swipeOffset = currentOffset
        triggerStateChanges = prevValue
    }

    /** Refresh method to be used when you want to dynamically change the left or right buttons (add or remove)
     * If you only want to change the title or the backgroundColor of a button you can change it's properties (get the button instance from leftButtons or rightViews arrays)
     * @param usingDelegate if YES new buttons will be fetched using the SwipeTableCellDelegate. Otherwise new buttons will be fetched from leftButtons/rightViews properties.
     */
    public func refreshButtons(_ usingDelegate: Bool) {
        if usingDelegate {
            rightViews = [UIView]()
        }

        rightView?.removeFromSuperview()
        rightView = nil

        createSwipeViewIfNeeded()
        refreshContentView()
    }

    // MARK: Gestures

    public func cancelPanGesture() {
        if panRecognizer?.state != .ended && panRecognizer?.state != .possible {
            panRecognizer?.isEnabled = false
            panRecognizer?.isEnabled = true
            if swipeOffset {
                hideSwipe(animated: true)
            }
        }
    }

    func filterSwipe(offset: Double) -> Double {
        var allowed = offset > 0 ? allowSwipeLeftToRight : allowSwipeRightToLeft
        UIView *curViews = offset > 0 ? leftView : rightView
        if curViews == nil || !allowed {
            offset = 0
        } else if !allowsOppositeSwipe && firstSwipeState == .swipingLeftToRight && offset < 0 {
            offset = 0
        } else if !allowsOppositeSwipe && firstSwipeState == .swipingRightToLeft && offset > 0 {
            offset = 0
        }
        return offset
    }

    @objc private func tapHandler(gesture recognizer: UITapGestureRecognizer) {
        var hide = true
        hide = swipeDelegate?.swipeTableCell(self, shouldHideSwipeOnTap: recognizer.location(in: self))
        if hide {
            hideSwipe(animated: true)
        }
    }

    @objc private func panHandler(gesture: UIPanGestureRecognizer) {
        let current = gesture.translation(in: self)
        if gesture.state == .began {
            invalidateDisplayLink()
            if !preservesSelectionStatus {
                isHighlighted = false
            }
            createSwipeViewIfNeeded()
            panStartPoint = current
            panStartOffset = swipeOffset
            if swipeOffset != 0 {
                firstSwipeState = swipeOffset > 0 ? .swipingLeftToRight : .swipingRightToLeft
            }

            if !allowsMultipleSwipe {
                let cells = parentTableView()?.visibleCells
                for cell in cells {
                    if cell.isKind(of: SwipeTableCell.self) && cell != self {
                        cell.cancelPanGesture()
                    }
                }
            }
        } else if gesture.state == .changed {
            let offset = panStartOffset + current.x - panStartPoint.x
            if firstSwipeState == .none {
                firstSwipeState = offset > 0 ? .swipingLeftToRight : .swipingRightToLeft
            }
            swipeOffset = filterSwipe(offset: offset)
        } else {
            var expansion = false
            if expansion {
                // TODO:
            } else {
                let velocity = panRecognizer?.velocity(in: self).x
                let inertiaThreshold = 100.0
                if velocity > inertiaThreshold {
                    targetOffset = swipeOffset < 0 ? 0 : (leftView && leftSwipeSettings?.keepButtonsSwiped ? CGRectGetWidth(leftView?.bounds) : targetOffset)
                } else if velocity < -inertiaThreshold {
                    targetOffset = swipeOffset > 0 ? 0 : (rightView && rightSwipeSettings?.keepButtonsSwiped ? -CGRectGetWidth(rightView?.bounds) : targetOffset)
                }
                targetOffset = filterSwipe(offset: targetOffset)
                let settings = swipeOffset > 0 ? leftSwipeSettings : rightSwipeSettings
                var animation: SwipeAnimation?

                if targetOffset == 0 {
                    animation = settings?.hideAnimation
                } else if fabs(swipeOffset) > fabs(targetOffset) {
                    animation = settings?.stretchAnimation
                } else {
                    animation = settings?.showAnimation
                }
                setSwipeOffset(targetOffset, animated: animation, completion: nil)
            }
            firstSwipeState = .none
        }
    }

    func gestureRecognizerShouldBegin(gesture: UIGestureRecognizer) -> Bool {
        if gesture == panRecognizer {
            if isEditing {
                return false // do not swipe while editing table
            }

            // user is scrolling vertically
            let transition = panRecognizer?.translation(in: self)
            if fabs(transition.y) > fabs(transition.x) {
                return false
            }

            // user clicked outside the cell or in the buttons area
            if swipeView {
                let point = tapRecognizer?.location(in: swipeView)
                if !CGRectContainsPoint(swipeView?.bounds, point) {
                    return allowsSwipeWhenTappingUiews
                }
            }

            // already swiped, don't need to check buttons or canSwipe delegate
            if swipeOffset != 0.0 {
                return true
            }

            // make a decision according to existing buttons or using the optional delegate
            if let swipeDelegate = swipeDelegate {
                CGPoint curPoint = gesture.location(in: self)
                if let allowLTR = swipeDelegate.swipeTableCell(self, canSwipe: .leftToRight, from: curPoint) {
                    allowSwipeLeftToRight = allowLTR
                } else {
                    fetchButtonsIfNeed()
                    allowSwipeLeftToRight = leftViews?.count > 0
                }

                if let allowRTL = swipeDelegate.swipeTableCell(self, canSwipe: .rightToLeft, from: curPoint) {
                    allowSwipeRightToLeft = allowRTL
                } else {
                    fetchButtonsIfNeed()
                    allowSwipeRightToLeft = rightViews?.count > 0
                }
            }
            return (allowSwipeLeftToRight && translation.x > 0) || (allowSwipeRightToLeft && translation.x < 0)
        } else if gesture == tapRecognizer {
            let point = tapRecognizer?.location(in: swipeView)
            return CGRectContainsPoint(swipeView?.bounds, point)
        }
        return true
    }

    /** check if the user swipe gesture is currently active */
    public func isSwipeGestureActive() -> Bool {
        panRecognizer?.state == .began || panRecognizer?.state == .changed
    }

    func setSwipeBackgroundColor(backgroundColor: UIColor) {
        swipeBackgroundColor = backgroundColor
        if let swipeOverlay = swipeOverlay {
            swipeOverlay.backgroundColor = backgroundColor
        }
    }

    // MARK: Accessibility

    override public func accessibilityElementCount() -> Int {
        swipeOffset == 0 ? super.accessibilityElementCount() : 1
    }

    override public func accessibilityElement(at index: Int) -> Any? {
        swipeOffset == 0 ? super.accessibilityElement(at: index) : contentView
    }

    override public func index(ofAccessibilityElement element: Any) -> Int {
        swipeOffset == 0 ? super.index(ofAccessibilityElement: element) : 0
    }
}
