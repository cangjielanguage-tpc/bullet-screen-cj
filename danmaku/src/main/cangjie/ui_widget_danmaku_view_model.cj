/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class DanmakuViewModel <: IDanmakuView {
    var delegate: ?DanmakuView = None
    let userArgs: ArrayList<(DanmakuView) -> Unit> = ArrayList<(DanmakuView) -> Unit>()
    func setDanmakuView(d: DanmakuView) {
        this.delegate = d
        this.delegate?.prepareInner()
        for (call in userArgs) {
            call(d)
        }
        userArgs.clear()
    }

    public func backgroundColor(color: UInt32): Unit {
        this.backgroundColor(Color(color))
    }
    public func backgroundColor(color: Color): Unit {
        if (let Some(v) <- this.delegate) {
            v.setBackgroundColor(color)
        } else {
            userArgs.add({
                view => view.setBackgroundColor(color)
            })
        }
    }

    public override func isPrepared(): Bool {
        if (let Some(v) <- this.delegate) {
            v.isPrepared()
        } else {
            throw NoneValueException()
        }
    }
    public override func isPaused(): Bool {
        if (let Some(v) <- this.delegate) {
            v.isPaused()
        } else {
            throw NoneValueException()
        }
    }

    /**
     *
     * @param type One of THREAD_TYPE_MAIN_THREAD, THREAD_TYPE_HIGH_PRIORITY, THREAD_TYPE_NORMAL_PRIORITY, or THREAD_TYPE_LOW_PRIORITY.
     */
    public override func setDrawingThreadType(threadType: Int64): Unit {
        if (let Some(v) <- this.delegate) {
            v.setDrawingThreadType(threadType)
        } else {
            userArgs.add({
                view => view.setDrawingThreadType(threadType)
            })
        }
    }

    public override func enableDanmakuDrawingCache(enable: Bool): Unit {
        if (let Some(v) <- this.delegate) {
            v.enableDanmakuDrawingCache(enable)
        } else {
            userArgs.add({
                view => view.enableDanmakuDrawingCache(enable)
            })
        }
    }

    public override func isDanmakuDrawingCacheEnabled(): Bool {
        (this.delegate?.isDanmakuDrawingCacheEnabled()).getOrThrow()
    }

    public override func showFPS(show: Bool): Unit {
        if (let Some(v) <- this.delegate) {
            v.showFPS(show)
        } else {
            userArgs.add({
                view => view.showFPS(show)
            })
        }
    }

    /**
     * danmaku.isLive == true的情况下,请在非UI线程中使用此方法,避免可能卡住主线程. TODO
     * @param item
     */
    public override func addDanmaku(item: BaseDanmaku): Unit {
        if (let Some(v) <- this.delegate) {
            v.addDanmaku(item)
        } else {
            userArgs.add({
                view => view.addDanmaku(item)
            })
        }
    }

    public override func invalidateDanmaku(item: BaseDanmaku, remeasure: Bool): Unit {
        if (let Some(v) <- this.delegate) {
            v.invalidateDanmaku(item, remeasure)
        } else {
            userArgs.add({
                view => view.invalidateDanmaku(item, remeasure)
            })
        }
    }

    public override func removeAllDanmakus(isClearDanmakusOnScreen: Bool): Unit {
        if (let Some(v) <- this.delegate) {
            v.removeAllDanmakus(isClearDanmakusOnScreen)
        } else {
            userArgs.add({
                view => view.removeAllDanmakus(isClearDanmakusOnScreen)
            })
        }
    }

    public override func removeAllLiveDanmakus(): Unit {
        if (let Some(v) <- this.delegate) {
            v.removeAllLiveDanmakus()
        } else {
            userArgs.add({
                view => view.removeAllLiveDanmakus()
            })
        }
    }

    public override func getCurrentVisibleDanmakus(): ?IDanmakus {
        return (this.delegate?.getCurrentVisibleDanmakus()).getOrThrow()
    }

    public override func setCallback(callback: DanmakuCallBack): Unit {
        if (let Some(v) <- this.delegate) {
            v.setCallback(callback)
        } else {
            userArgs.add({
                view => view.setCallback(callback)
            })
        }
    }

    /**
     * for getting the accurate play-time. use this method instead of parser.getTimer().currMillisecond
     * @return
     */
    public override func getCurrentTime(): Int64 {
        return (this.delegate?.getCurrentTime()).getOrThrow()
    }

    public override func getConfig(): ?DanmakuContext {
        return (this.delegate?.getConfig()).getOrThrow()
    }

    // ------------- View方法  --------------------
    public override func getView(): IDanmakuView {
        return this
    }

    public func setWidth(width: Int64): Unit {
        this.setWidth(Float64(width))
    }

    public func setWidth(width: Float64): Unit {
        if (let Some(v) <- this.delegate) {
            v.setViewWidth(width)
        } else {
            userArgs.add({
                view => view.setViewWidth(width)
            })
        }
    }

    public func setHeight(height: Int64): Unit {
        this.setHeight(Float64(height))
    }
    public func setHeight(height: Float64): Unit {
        if (let Some(v) <- this.delegate) {
            v.setViewHeight(height)
        } else {
            userArgs.add({
                view => view.setViewHeight(height)
            })
        }
    }

    public override func getWidth(): Float64 {
        return (this.delegate?.getViewWidth()).getOrThrow()
    }

    public override func getHeight(): Float64 {
        return (this.delegate?.getViewHeight()).getOrThrow()
    }

    public override func setVisibility(visibility: Bool): Unit {
        if (let Some(v) <- this.delegate) {
            v.mDanmakuVisible = visibility
        } else {
            userArgs.add({
                view => view.mDanmakuVisible = visibility
            })
        }
    }

    public override func isShown(): Bool {
        return (this.delegate?.isShown()).getOrThrow()
    }

    // ------------- 播放控制 -------------------

    public override func prepare(parser: BaseDanmakuParser, config: DanmakuContext): Unit {
        if (let Some(v) <- this.delegate) {
            v.prepare(parser, config)
        } else {
            userArgs.add({
                view => view.prepare(parser, config)
            })
        }
    }

    public override func seekTo(ms: Int64): Unit {
        if (let Some(v) <- this.delegate) {
            v.seekTo(ms)
        } else {
            userArgs.add({
                view => view.seekTo(ms)
            })
        }
    }

    public override func start(): Unit {
        this.start(0)
    }
    public override func start(position: Int64): Unit {
        let pos: Int64 = max(position, 0)
        if (let Some(v) <- this.delegate) {
            v.start(pos)
        } else {
            userArgs.add({
                view => view.start(pos)
            })
        }
    }

    public override func stop(): Unit {
        if (let Some(v) <- this.delegate) {
            v.stop()
        } else {
            userArgs.add({
                view => view.stop()
            })
        }
    }

    public override func pause(): Unit {
        if (let Some(v) <- this.delegate) {
            v.pause()
        } else {
            userArgs.add({
                view => view.pause()
            })
        }
    }

    public override func resume(): Unit {
        if (let Some(v) <- this.delegate) {
            v.resume()
        } else {
            userArgs.add({
                view => view.resume()
            })
        }
    }

    public override func release(): Unit {
        if (let Some(v) <- this.delegate) {
            v.release()
        } else {
            userArgs.add({
                view => view.release()
            })
        }
    }

    public override func toggle(): Unit {
        if (let Some(v) <- this.delegate) {
            v.toggle()
        } else {
            userArgs.add({
                view => view.toggle()
            })
        }
    }

    public override func show(): Unit {
        if (let Some(v) <- this.delegate) {
            v.show()
        } else {
            userArgs.add({
                view => view.show()
            })
        }
    }

    public override func hide(): Unit {
        if (let Some(v) <- this.delegate) {
            v.hide()
        } else {
            userArgs.add({
                view => view.hide()
            })
        }
    }

    /**
     * show the danmakuview again if you called hideAndPauseDrawTask()
     * @param position The position you want to resume
     * @see #hideAndPauseDrawTask
     */
    public override func showAndResumeDrawTask(position: Int64): Unit {
                if (let Some(v) <- this.delegate) {
            v.showAndResumeDrawTask(position)
        } else {
            userArgs.add({
                view => view.showAndResumeDrawTask(position)
            })
        }
    }

    /**
     * hide the danmakuview and pause the drawtask
     * @return the paused position
     * @see #showAndResumeDrawTask
     */
    public override func hideAndPauseDrawTask(): Int64 {
        return (this.delegate?.hideAndPauseDrawTask()).getOrThrow()
    }

    public override func clearDanmakusOnScreen(): Unit {
                if (let Some(v) <- this.delegate) {
            v.clearDanmakusOnScreen()
        } else {
            userArgs.add({
                view => view.clearDanmakusOnScreen()
            })
        }
    }

    // ------------- Click Listener -------------------
    public override func setOnDanmakuClickListener(listener: OnDanmakuClickListener): Unit {
        if (let Some(v) <- this.delegate) {
            v.mOnDanmakuClickListener = listener
        } else {
            userArgs.add({
                view => view.mOnDanmakuClickListener = listener
            })
        }
    }
    public override func setOnDanmakuClickListener(listener: OnDanmakuClickListener, xOff: Float64, yOff: Float64): Unit {
        if (let Some(v) <- this.delegate) {
            v.mOnDanmakuClickListener = listener
            v.mXOff = xOff
            v.mYOff = yOff
        } else {
            userArgs.add({view =>
                view.mOnDanmakuClickListener = listener
                view.mXOff = xOff
                view.mYOff = yOff
            })
        }
    }

    public override func getOnDanmakuClickListener(): ?OnDanmakuClickListener {
        return if (let Some(v) <- this.delegate) {
            v.getOnDanmakuClickListener()
        } else {
            None
        }
    }

    public override func getXOff(): Float64 {
        return (this.delegate?.getXOff()).getOrThrow()
    }

    public override func getYOff(): Float64 {
        return (this.delegate?.getYOff()).getOrThrow()
    }

    public override func forceRender(): Unit {
        if (let Some(v) <- this.delegate) {
            v.forceRender()
        } else {
            userArgs.add({
                view => view.forceRender()
            })
        }
    }
}
