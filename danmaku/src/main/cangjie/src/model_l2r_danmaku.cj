/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class L2RDanmaku <: R2LDanmaku {
    public init(duration: DanmakuDuration) {
        super(duration)
    }

    public override func layout(displayer: IDisplayer, x: Float64, y: Float64): Unit {
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

    protected override func getAccurateLeft(displayer: IDisplayer, currTime: Int64): Float64 {
        let elapsedTime: Int64 = currTime - getActualTime()
        if (elapsedTime >= duration.value) {
            return displayer.getWidth()
        }
        return mStepX * Float64(elapsedTime) - paintWidth
    }

    public override func getRectAtTime(displayer: IDisplayer, time: Int64): ?Array<Float64> {
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

    public override func getType(): Int64 {
        return BaseDanmaku.TYPE_SCROLL_LR
    }
}
