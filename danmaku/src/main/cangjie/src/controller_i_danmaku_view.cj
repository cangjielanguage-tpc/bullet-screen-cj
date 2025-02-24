/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public let THREAD_TYPE_NORMAL_PRIORITY = 0x0
public let THREAD_TYPE_MAIN_THREAD = 0x1
public let THREAD_TYPE_HIGH_PRIORITY = 0x2
public let THREAD_TYPE_LOW_PRIORITY = 0x3

public interface IDanmakuView {

    public func isPrepared(): Bool

    public func isPaused(): Bool

    // public func isHardwareAccelerated(): Bool
    /**
     *
     * @param type One of THREAD_TYPE_MAIN_THREAD, THREAD_TYPE_HIGH_PRIORITY, THREAD_TYPE_NORMAL_PRIORITY, or THREAD_TYPE_LOW_PRIORITY.
     */
    public func setDrawingThreadType(ty: Int64): Unit

    public func enableDanmakuDrawingCache(enable: Bool): Unit

    public func isDanmakuDrawingCacheEnabled(): Bool

    public func showFPS(show: Bool): Unit

    /**
     * danmaku.isLive == true的情况下,请在非UI线程中使用此方法,避免可能卡住主线程
     * @param item
     */
    public func addDanmaku(item: BaseDanmaku ): Unit

    public func invalidateDanmaku(item: BaseDanmaku , remeasure: Bool): Unit

    public func removeAllDanmakus(isClearDanmakusOnScreen: Bool): Unit

    public func removeAllLiveDanmakus(): Unit

    public func getCurrentVisibleDanmakus(): ?IDanmakus

    public func setCallback(callback: DanmakuCallBack): Unit

    /**
     * for getting the accurate play-time. use this method intead of parser.getTimer().currMillisecond
     * @return
     */
    public func getCurrentTime(): Int64

    public func getConfig(): ?DanmakuContext

    // ------------- View方法  --------------------

    func getView(): IDanmakuView

    func getWidth(): Float64

    func getHeight(): Float64

    func setVisibility(visibility: Bool): Unit

    func isShown(): Bool


    // ------------- 播放控制 -------------------

    func prepare(parser: BaseDanmakuParser, config: DanmakuContext): Unit

    func seekTo(ms: Int64): Unit

    func start(): Unit
    func start(position: Int64): Unit

    func stop(): Unit

    func pause(): Unit

    func resume(): Unit

    func release(): Unit

    func toggle(): Unit

    func show(): Unit

    func hide(): Unit

    /**
     * show the danmakuview again if you called hideAndPauseDrawTask()
     * @param position The position you want to resume
     * @see #hideAndPauseDrawTask
     */
    func showAndResumeDrawTask(position: Int64): Unit

    /**
     * hide the danmakuview and pause the drawtask
     * @return the paused position
     * @see #showAndResumeDrawTask
     */
    func hideAndPauseDrawTask(): Int64

    func clearDanmakusOnScreen(): Unit

    // ------------- Click Listener -------------------
    func setOnDanmakuClickListener(listener: OnDanmakuClickListener): Unit

    func setOnDanmakuClickListener(listener: OnDanmakuClickListener, xOff: Float64, yOff: Float64): Unit

    func getOnDanmakuClickListener(): ?OnDanmakuClickListener

    func getXOff(): Float64

    func getYOff(): Float64

    func forceRender(): Unit
}

public interface OnDanmakuClickListener {
    /**
     * @param danmakus all to be clicked, this value may be empty;
     *                 danmakus.last() is the latest danmaku which may be null;
     * @return True if the event was handled, false otherwise.
     */
    func onDanmakuClick(danmakus: IDanmakus): Bool;

    func onDanmakuLongClick(danmakus: IDanmakus): Bool;

    func onViewClick(view: IDanmakuView): Bool;
}
