/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

import ohos.component.TouchEvent
import ohos.component.TouchType

public interface SimpleOnGestureListener {
    func onDown(event: TouchEvent): Bool

    func onSingleTapConfirmed(event: TouchEvent): Bool

    func onLongPress(event: TouchEvent): Unit
}

public class DanmakuTouchHelper {
    static let nullTouchDelegate = unsafe { zeroValue<GestureDetector>() } // 一定初始化， 不用处理
    var mTouchDelegate: GestureDetector
    var danmakuView: IDanmakuView
    var mDanmakuBounds: RectF
    var mXOff: Float64 = 0.0
    var mYOff: Float64 = 0.0

    public func getDanmakuView(): IDanmakuView {
        return this.danmakuView
    }

    public func setmXOff(mXOff: Float64): Unit {
        this.mXOff = mXOff
    }

    public func setmYOff(mYOff: Float64): Unit {
        this.mYOff = mYOff
    }

    init(danmakuView: IDanmakuView) {
        this.danmakuView = danmakuView
        this.mDanmakuBounds = RectF()
        this.mTouchDelegate = nullTouchDelegate
        this.mTouchDelegate = GestureDetector(this)
    }

    public static func instance(danmakuView: IDanmakuView): DanmakuTouchHelper {
        return DanmakuTouchHelper(danmakuView)
    }

    public func onTouchEvent(event: TouchEvent): Bool {
        return this.mTouchDelegate.onTouchEvent(event)
    }

    public func performDanmakuClick(danmakus: IDanmakus, isLongClick: Bool): Bool {
        if (let Some(onDanmakuClickListener) <- this.danmakuView.getOnDanmakuClickListener()) {
            if (isLongClick) {
                return onDanmakuClickListener.onDanmakuLongClick(danmakus)
            } else {
                return onDanmakuClickListener.onDanmakuClick(danmakus)
            }
        }
        return false
    }

    public func performViewClick(): Bool {
        if (let Some(v) <- this.danmakuView.getOnDanmakuClickListener()) {
            return v.onViewClick(this.danmakuView)
        }
        return false
    }

    public func touchHitDanmaku(x: Float64, y: Float64): IDanmakus {
        let hitDanmakus: IDanmakus = Danmakus()
        this.mDanmakuBounds.setEmpty()
        let that = this
        if (let Some(danmakus) <- this.danmakuView.getCurrentVisibleDanmakus()) {
            if (danmakus.isEmpty()) {
                let danMUKuMessage = DefaultConsumer<BaseDanmaku>(
                    {
                        danmaku: BaseDanmaku =>
                        this.mDanmakuBounds.set(danmaku.getLeft(), danmaku.getTop(), danmaku.getRight(), danmaku.getBottom())
                        if (that.mDanmakuBounds.intersect(x - that.mXOff, y - that.mYOff, x + that.mXOff, y + that.mYOff
                        )) {
                            hitDanmakus.addItem(danmaku)
                        }
                        return ACTION_CONTINUE
                    }
                )
                danmakus.forEachSync(danMUKuMessage)
            }
        }

        return hitDanmakus
    }
}

class GestureDetector <: SimpleOnGestureListener {
    private let TIME_LONG_PRESS: Int64 = 600
    private var startTime: Int64 = 0
    private var endTime: Int64 = 0
    private var danmakuTouchHelper: DanmakuTouchHelper

    public init(danmakuTouchHelper: DanmakuTouchHelper) {
        this.danmakuTouchHelper = danmakuTouchHelper
    }

    func onTouchEvent(event: TouchEvent): Bool {
        match (event.eventType) {
            case TouchType.Down =>
                this.startTime = SystemClock.uptimeMillis()
                this.onDown(event)
            case TouchType.Up =>
                this.endTime = SystemClock.uptimeMillis()
                let pressTime = this.endTime - this.startTime
                if (pressTime < this.TIME_LONG_PRESS) {
                    this.onSingleTapConfirmed(event)
                } else {
                    this.onLongPress(event)
                }
            case _ => ()
        }

        return false
    }

    public func onDown(event: TouchEvent): Bool {
        if (let Some(_) <- this.danmakuTouchHelper.getDanmakuView().getOnDanmakuClickListener()) {
            this.danmakuTouchHelper.setmXOff(this.danmakuTouchHelper.getDanmakuView().getXOff())
            this.danmakuTouchHelper.setmYOff(this.danmakuTouchHelper.getDanmakuView().getYOff())
            return true
        }
        return false
    }

    public func onSingleTapConfirmed(event: TouchEvent): Bool {
        let clickDanmakus: IDanmakus = this.danmakuTouchHelper.touchHitDanmaku(event.touches[0].x, event.touches[0].y)
        var isEventConsumed: Bool = false
        if (!clickDanmakus.isEmpty()) {
            isEventConsumed = this.danmakuTouchHelper.performDanmakuClick(clickDanmakus, false)
        }
        if (!isEventConsumed) {
            isEventConsumed = this.danmakuTouchHelper.performViewClick()
        }
        return isEventConsumed
    }

    public func onLongPress(event: TouchEvent): Unit {
        if (this.danmakuTouchHelper.getDanmakuView().getOnDanmakuClickListener().isNone()) {
            return
        }
        this.danmakuTouchHelper.setmXOff(this.danmakuTouchHelper.getDanmakuView().getXOff())
        this.danmakuTouchHelper.setmYOff(this.danmakuTouchHelper.getDanmakuView().getYOff())
        let clickDanmakus: IDanmakus = this.danmakuTouchHelper.touchHitDanmaku(event.touches[0].x, event.touches[0].y)
        if (!clickDanmakus.isEmpty()) {
            this.danmakuTouchHelper.performDanmakuClick(clickDanmakus, true)
        }
    }
}
