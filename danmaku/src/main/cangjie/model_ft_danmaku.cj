/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public open class FTDanmaku <: BaseDanmaku {
    private var x: Float64 = 0.0
    protected var y: Float64 = -1.0
    private var RECT: Array<Float64> = NullArray
    private var mLastLeft: Float64 = 0.0
    private var mLastPaintWidth: Float64 = 0.0
    private var mLastDispWidth: Float64 = 0.0

    public init(duration: DanmakuDuration) {
        super()
        this.duration = duration
    }

    public override func layout(displayer: IDisplayer, _: Float64, _: Float64): Unit {
        if (let Some(mTimer) <- mTimer) {
            let deltaDuration: Int64 = mTimer.currMillisecond - getActualTime()
            if (deltaDuration > 0 && deltaDuration < duration.value) {
                if (!isShown()) {
                    this.x = getLeftWithDisplayer(displayer)
                    this.y = y
                    setVisibility(true)
                }
                return
            }
            setVisibility(false)
            this.y = -1.0
            this.x = displayer.getWidth()
        }
    }

    public func getLeftWithDisplayer(displayer: IDisplayer): Float64 {
        if (mLastDispWidth == displayer.getWidth() && mLastPaintWidth == paintWidth) {
            return mLastLeft
        }
        let left: Float64 = (displayer.getWidth() - paintWidth) / 2.0
        mLastDispWidth = displayer.getWidth()
        mLastPaintWidth = paintWidth
        mLastLeft = left
        return left
    }

    public override func getRectAtTime(displayer: IDisplayer, _: Int64): Array<Float64> {
        if (!isMeasured()) {
            return NullArray
        }
        let left: Float64 = getLeftWithDisplayer(displayer)
        if (RECT.size == 0) {
            RECT = Array<Float64>(4, repeat: 0.0)
        }
        RECT[0] = left
        RECT[1] = y
        RECT[2] = left + paintWidth
        RECT[3] = y + paintHeight
        return RECT
    }

    public override func getLeft(): Float64 {
        return x
    }

    public override func getTop(): Float64 {
        return y
    }

    public override func getRight(): Float64 {
        return x + paintWidth
    }

    public override func getBottom(): Float64 {
        return y + paintHeight
    }

    public open func getType(): Int64 {
        return BaseDanmaku.TYPE_FIX_TOP
    }
}
