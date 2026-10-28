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

    func setOnDanmakuShownListener(onDanmakuShown: (BaseDanmaku) -> Unit): Unit

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
    let lock = ReentrantMutex()
   public var isRunningDanmakus: Bool = false
   public var timer: DanmakuTimer = DanmakuTimer()
   public var indexInScreen: Int64 = 0
   public var totalSizeInScreen: Int64  = 0
   public var lastDanmaku: ?BaseDanmaku = None

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
   public var nothingRendered: Bool = false
   public var sysTime: Int64 = 0
   public var cacheHitCount: Int64 = 0
   public var cacheMissCount: Int64 = 0

   private var runningDanmakus: IDanmakus = Danmakus(ST_BY_LIST)
   private var mIsObtaining: Bool = false

   public func addTotalCount(count: Int64): Int64 {
       totalDanmakuCount += count
       return totalDanmakuCount
   }

   public func addCount(typ: Int64, count: Int64): Int64 {
       match {
           case typ == BaseDanmaku.TYPE_SCROLL_RL =>
               r2lDanmakuCount += count
               return r2lDanmakuCount
           case typ == BaseDanmaku.TYPE_SCROLL_LR =>
               l2rDanmakuCount += count
               return l2rDanmakuCount
           case typ == BaseDanmaku.TYPE_FIX_TOP =>
               ftDanmakuCount += count
               return ftDanmakuCount
           case typ == BaseDanmaku.TYPE_FIX_BOTTOM =>
               fbDanmakuCount += count
               return fbDanmakuCount
           case typ == BaseDanmaku.TYPE_SPECIAL =>
               specialDanmakuCount += count
               return specialDanmakuCount
            case _ => return 0
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
       synchronized (lock) {
           runningDanmakus.clear()
       }
   }

   public func set(other: ?RenderingState): Unit {
        let that = other ?? return ()
        lastTotalDanmakuCount = that.lastTotalDanmakuCount
        r2lDanmakuCount = that.r2lDanmakuCount
        l2rDanmakuCount = that.l2rDanmakuCount
        ftDanmakuCount = that.ftDanmakuCount
        fbDanmakuCount = that.fbDanmakuCount
        specialDanmakuCount = that.specialDanmakuCount
        totalDanmakuCount = that.totalDanmakuCount
        consumingTime = that.consumingTime
        beginTime = that.beginTime
        endTime = that.endTime
        nothingRendered = that.nothingRendered
        sysTime = that.sysTime
        cacheHitCount = that.cacheHitCount
        cacheMissCount = that.cacheMissCount
   }

   public func appendToRunningDanmakus(danmaku: BaseDanmaku): Unit {
       if (!mIsObtaining) {
           runningDanmakus.addItem(danmaku)
       }
   }

   public func obtainRunningDanmakus(): IDanmakus {
       mIsObtaining = true
       var danmakus: IDanmakus
       synchronized (lock) {
           danmakus = runningDanmakus
           runningDanmakus = Danmakus(ST_BY_LIST)
       }
       mIsObtaining = false
       return danmakus
   }

}
