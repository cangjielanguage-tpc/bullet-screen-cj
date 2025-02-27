/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public abstract class Proxy {
    /**
     * 在弹幕显示前使用新的text
     * @param danmaku
     * @param fromWorkerThread 是否在工作(非UI)线程,在true的情况下可以做一些耗时操作(例如更新Span的drawblae或者其他IO操作)
     * @return 如果不需重置，直接返回danmaku.text
     */
    public func prepareDrawing(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit

    public func releaseResource(danmaku: BaseDanmaku): Unit
}

public abstract class BaseCacheStuffer <: Equatable<BaseCacheStuffer> {
    public var mProxy: ?Proxy = None
    var bitmaps: ?HashMap<String, ImageBitmap> = None
    public func prepare(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit {
        if (let Some(v) <- mProxy) {
            v.prepareDrawing(danmaku, fromWorkerThread)
        }
    }

    /**
     * set paintWidth, paintHeight to danmaku
     * @param danmaku
     * @param fromWorkerThread
     */
    public func measure(danmaku: BaseDanmaku, paint: DanmakuPaint, fromWorkerThread: Bool): Unit

    /**
     * clear caches which created by this stuffer
     */
    public func clearCaches(): Unit

    public func drawDanmaku(danmaku: BaseDanmaku, canvas: DanmakuCanvas2D, left: Float64, top: Float64,
        fromWorkerThread: Bool, displayerConfig: DisplayerConfig): Unit

    public func clearCache(danmaku: BaseDanmaku): Unit {
    }

    public func setProxy(adapter: ?Proxy): Unit {
        this.mProxy = adapter
    }

    public func releaseResource(danmaku: BaseDanmaku): Unit {
        if (let Some(v) <- mProxy) {
            v.releaseResource(danmaku)
        }
    }

    public operator func ==(that: BaseCacheStuffer): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: BaseCacheStuffer): Bool {
        return !(this == that)
    }
}
