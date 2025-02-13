//
//  SwipeAnimation.swift
//  Dola
//
//  Created by MagicianQuinn on 2025/1/9.
//
//

// TODO: Support border, clip, rotate3D and so on...
public enum SwipeTransition: Int {
    case drag = 0
    case `static`
    case border
}

public enum SwipeDirection: Int {
    case leftToRight = 0
    case rightToLeft
}

public enum SwipeState: Int {
    case none = 0
    case swipingLeftToRight
    case swipingRightToLeft
}

public enum SwipeEasingFunction: Int {
    case linear = 0

    case quadIn

    case quadOut

    case quadInOut

    case cubicIn

    case cubicOut

    case cubicInOut

    case bounceIn

    case bounceOut

    case bounceInOut
}

public class SwipeAnimation {
    /** Animation duration in seconds. */
    public var duration: Double = 0.3

    /** Animation easing function. */
    public var easingFunction: SwipeEasingFunction = .bounceOut

    static func easeLinear(_ t: Double, _ b: Double, _ c: Double) -> Double {
        c * t + b
    }

    static func easeInQuad(_ t: Double, _ b: Double, _ c: Double) -> Double {
        c * t * t + b
    }

    static func easeOutQuad(_ t: Double, _ b: Double, _ c: Double) -> Double {
        -c * t * (t - 2) + b
    }

    static func easeInOutQuad(_ tmp: Double, _ b: Double, _ c: Double) -> Double {
        var t = tmp
        t = t * 2
        if t < 1 {
            return c / 2 * t * t + b
        } else {
            t = t - 1
            return -c / 2 * (t * (t - 2) - 1) + b
        }
    }

    static func easeInCubic(_ t: Double, _ b: Double, _ c: Double) -> Double {
        c * t * t * t + b
    }

    static func easeOutCubic(_ tmp: Double, _ b: Double, _ c: Double) -> Double {
        var t = tmp
        t = t - 1
        return c * (t * t * t + 1) + b
    }

    static func easeInOutCubic(_ tmp: Double, _ b: Double, _ c: Double) -> Double {
        var t = tmp
        t *= 2
        if t < 1 {
            return c / 2 * t * t * t + b
        } else {
            t -= 2
            return c / 2 * (t * t * t + 2) + b
        }
    }

    static func easeOutBounce(_ tmp: Double, _ b: Double, _ c: Double) -> Double {
        var t = tmp
        if t < (1 / 2.75) {
            return c * (7.5625 * t * t) + b
        } else if t < (2 / 2.75) {
            t -= (1.5 / 2.75)
            return c * (7.5625 * t * t + 0.75) + b
        } else if t < (2.5 / 2.75) {
            t -= (2.25 / 2.75)
            return c * (7.5625 * t * t + 0.9375) + b
        } else {
            t -= (2.625 / 2.75)
            return c * (7.5625 * t * t + 0.984375) + b
        }
    }

    static func easeInBounce(_ t: Double, _ b: Double, _ c: Double) -> Double {
        c - easeOutBounce(1.0 - t, 0, c) + b
    }

    static func easeInOutBounce(_ t: Double, _ b: Double, _ c: Double) -> Double {
        if t < 0.5 {
            return easeInBounce(t * 2, 0, c) * 0.5 + b
        } else {
            return easeOutBounce(1.0 - t * 2, 0, c) * 0.5 + c * 0.5 + b
        }
    }

    public func swipeAnimation(esapsed: Double, duration: Double, from: Double, to: Double) -> Double {
        let t = min(esapsed / duration, 1.0)
        if t == 1.0 {
            return to
        }

        let b = from
        let c = to - from

        var easingValue: Double = 0
        switch easingFunction {
        case .linear:
            return SwipeAnimation.easeLinear(t, b, c)
        case .quadIn:
            return SwipeAnimation.easeInQuad(t, b, c)
        case .quadOut:
            return SwipeAnimation.easeOutQuad(t, b, c)
        case .quadInOut:
            return SwipeAnimation.easeInOutQuad(t, b, c)
        case .cubicIn:
            return SwipeAnimation.easeInCubic(t, b, c)
        case .cubicOut:
            return SwipeAnimation.easeOutCubic(t, b, c)
        case .cubicInOut:
            return SwipeAnimation.easeInOutCubic(t, b, c)
        case .bounceIn:
            return SwipeAnimation.easeInBounce(t, b, c)
        case .bounceOut:
            return SwipeAnimation.easeOutBounce(t, b, c)
        case .bounceInOut:
            return SwipeAnimation.easeInOutBounce(t, b, c)
        }
    }
}
