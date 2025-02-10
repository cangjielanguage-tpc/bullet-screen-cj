/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public open class R2LDanmaku <: BaseDanmaku {
    protected static let MAX_RENDERING_TIME: Int64 = 100
    protected static let CORDON_RENDERING_TIME: Int64 = 40
    protected var x: Float64 = 0.0
    protected var y: Float64 = -1.0
    protected var mDistance: Float64 = 0.0
    protected var RECT: ?Array<Float64> = None
    protected var mStepX: Float64 = 0.0
    protected var mLastTime: Int64 = 0

    init(duration: DanmakuDuration) {
        super()
        this.duration = duration
    }

    public open override func layout(displayer: IDisplayer, x: Float64, y: Float64): Unit {
        if (let Some(timer) <- mTimer) {
            let currMS: Int64 = timer.currMillisecond
            let deltaDuration: Int64 = currMS - getActualTime()
            if (deltaDuration > 0 && deltaDuration < duration.value) {
                this.x = getAccurateLeft(displayer, currMS)
                if (!isShown()) {
                    this.y = y
                    setVisibility(true)
                }
                mLastTime = currMS
                return
            }
            mLastTime = currMS
        }
        setVisibility(false)
    }

    protected open func getAccurateLeft(displayer: IDisplayer, currTime: Int64): Float64 {
        let elapsedTime: Int64 = currTime - getActualTime()
        if (elapsedTime >= duration.value) {
            return -paintWidth
        }
        return displayer.getWidth() - Float64(elapsedTime) * mStepX
    }

    public open func getRectAtTime(displayer: IDisplayer, time: Int64): ?Array<Float64> {
        if (!isMeasured()) {
            return None
        }
        let left: Float64 = getAccurateLeft(displayer, time)
        if (RECT.isNone()) {
            RECT = Array<Float64>(4, item: 0.0)
        }
        RECT()[0] = left
        RECT()[1] = y
        RECT()[2] = left + paintWidth
        RECT()[3] = y + paintHeight
        return RECT
    }

    public open override func getLeft(): Float64 {
        return x
    }

    public open override func getTop(): Float64 {
        return y
    }

    public open override func getRight(): Float64 {
        return x + paintWidth
    }

    public open override func getBottom(): Float64 {
        return y + paintHeight
    }

    public open func getType(): Int64 {
        return BaseDanmaku.TYPE_SCROLL_RL
    }

    public override func measure(displayer: IDisplayer, fromWorkerThread: Bool): Unit {
        super.measure(displayer, fromWorkerThread)
        mDistance = displayer.getWidth() + paintWidth
        mStepX = mDistance / Float64(duration.value)
    }
}
