/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public interface IRenderer {
    func draw(disp: IDisplayer, danmakus: IDanmakus, startRenderTime: Int64, renderingState: RenderingState): Unit

    func clear(): Unit

    func clearRetainer(): Unit

    func release(): Unit

    func setVerifierEnabled(enabled: Bool): Unit

    func setOnDanmakuShownListener(onDanmakuShownListener: OnDanmakuShownListener): Unit

    func removeOnDanmakuShownListener(): Unit

    func alignBottom(enable: Bool): Unit
}

public interface OnDanmakuShownListener {
    func onDanmakuShown(danmaku: BaseDanmaku): Unit
}

public class DanmakuArea {
    public var mRefreshRect: Array<Float64> = [0.0, 0.0, 0.0, 0.0]
    private var mMaxHeight: Float64 = 0.0
    private var mMaxWidth: Float64 = 0.0

    public func setEdge(maxWidth: Float64, maxHeight: Float64): Unit {
        mMaxWidth = maxWidth
        mMaxHeight = maxHeight
    }

    public func reset(): Unit {
        set(mMaxWidth, mMaxHeight, 0.0, 0.0)
    }

    public func resizeToMax(): Unit {
        set(0.0, 0.0, mMaxWidth, mMaxHeight)
    }

    public func set(left: Float64, top: Float64, right: Float64, bottom: Float64): Unit {
        mRefreshRect[0] = left
        mRefreshRect[1] = top
        mRefreshRect[2] = right
        mRefreshRect[3] = bottom
    }
}

public class RenderingState {
    public static let UNKNOWN_TIME: Int64 = -1
    public var isRunningDanmakus: Bool = false
    public var timer: DanmakuTimer = DanmakuTimer(Option<Int64>.None)
    public var indexInScreen: Int64 = 0
    public var totalSizeInScreen: Int64 = 0
    public var lastDanmaku: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var r2lDanmakuCount: Int64 = 0
    public var l2rDanmakuCount: Int64 = 0
    public var ftDanmakuCount: Int64 = 0
    public var fbDanmakuCount: Int64 = 0
    public var specialDanmakuCount: Int64 = 0
    public var totalDanmakuCount: Int64 = 0
    public var lastTotalDanmakuCount: Int64 = 0
    public var consumingTime: Int64 = 0
    public var beginTime: Int64 = 0
    public var endTime: Int64 = 0
    public var nothingRendered: Bool = true
    public var sysTime: Int64 = 0
    public var cacheHitCount: Int64 = 0
    public var cacheMissCount: Int64 = 0
    private var runningDanmakus: IDanmakus = Danmakus(DanmakusArgs(sortType: ST_BY_LIST))
    private var mIsObtaining: Bool = false

    public func addTotalCount(count: Int64): Int64 {
        totalDanmakuCount += count
        return totalDanmakuCount
    }

    public func addCount(types: Int64, count: Int64): Int64 {
        return if (types == BaseDanmaku.TYPE_SCROLL_RL) {
            r2lDanmakuCount += count
            r2lDanmakuCount
        } else if (types == BaseDanmaku.TYPE_SCROLL_LR) {
            l2rDanmakuCount += count
            l2rDanmakuCount
        } else if (types == BaseDanmaku.TYPE_FIX_TOP) {
            ftDanmakuCount += count
            ftDanmakuCount
        } else if (types == BaseDanmaku.TYPE_FIX_BOTTOM) {
            fbDanmakuCount += count
            fbDanmakuCount
        } else if (types == BaseDanmaku.TYPE_SPECIAL) {
            specialDanmakuCount += count
            specialDanmakuCount
        } else {
            0
        }
    }

    public func reset(): Unit {
        lastTotalDanmakuCount = totalDanmakuCount
        r2lDanmakuCount = 0
        l2rDanmakuCount = 0
        ftDanmakuCount = 0
        fbDanmakuCount = 0
        specialDanmakuCount = 0
        totalDanmakuCount = 0
        sysTime = 0
        beginTime = 0
        endTime = 0
        consumingTime = 0
        nothingRendered = false
        runningDanmakus.clear()
    }

    public func set(other: ?RenderingState): Unit {
        if (let Some(other) <- other) {
            lastTotalDanmakuCount = other.lastTotalDanmakuCount
            r2lDanmakuCount = other.r2lDanmakuCount
            l2rDanmakuCount = other.l2rDanmakuCount
            ftDanmakuCount = other.ftDanmakuCount
            fbDanmakuCount = other.fbDanmakuCount
            specialDanmakuCount = other.specialDanmakuCount
            totalDanmakuCount = other.totalDanmakuCount
            consumingTime = other.consumingTime
            beginTime = other.beginTime
            endTime = other.endTime
            nothingRendered = other.nothingRendered
            sysTime = other.sysTime
            cacheHitCount = other.cacheHitCount
            cacheMissCount = other.cacheMissCount
        } else {
            return
        }
    }

    public func appendToRunningDanmakus(danmaku: BaseDanmaku): Unit {
        if (!mIsObtaining) {
            runningDanmakus.addItem(danmaku)
        }
    }

    public func obtainRunningDanmakus(): IDanmakus {
        mIsObtaining = true
        let danmakus: IDanmakus = runningDanmakus
        runningDanmakus = Danmakus(DanmakusArgs(sortType: ST_BY_LIST))
        mIsObtaining = false
        return danmakus
    }
}
