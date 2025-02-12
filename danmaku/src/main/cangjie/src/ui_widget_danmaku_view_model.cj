/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

// TODO  加锁
public class DanmakuViewModel <: IDanmakuView & IDanmakuViewController {
    var delegate: ?DanmakuView = None
    let userArgs: ArrayList<(DanmakuView) -> Unit> = ArrayList<(DanmakuView) -> Unit>()
    //    var hasDanmakuView: Bool = false
    //    let mon = Monitor()
    func setDanmakuView(d: DanmakuView) {
        //        this.mon.lock()
        this.delegate = d
        this.delegate?.prepareInner()
        for (call in userArgs) {
            call(d)
        }
        userArgs.clear()
    }

    //    func checkDanmakuView(): Unit {
    //        if (!this.hasDanmakuView) {
    //            this.mon.lock()
    //            this.mon.wait()
    //            this.mon.unlock()
    //        }
    //    }

    public func backgroundColor(color: UInt32): Unit {
        this.backgroundColor(Color(color))
    }
    public func backgroundColor(color: Color): Unit {
        if (let Some(v) <- this.delegate) {
            v.setBackgroundColor(color)
        } else {
            userArgs.append({
                view => view.setBackgroundColor(color)
            })
        }
    }

    public override func isPrepared(): Bool {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.isPrepared()
        } else {
            throw NoneValueException()
        }
    }
    public override func isPaused(): Bool {
        // this.checkDanmakuView()
        //        this.delegate.isPaused()
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
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.setDrawingThreadType(threadType)
        } else {
            userArgs.append({
                view => view.setDrawingThreadType(threadType)
            })
        }
        //        this.delegate.setDrawingThreadType(threadType)
    }

    public override func enableDanmakuDrawingCache(enable: Bool): Unit {
        if (let Some(v) <- this.delegate) {
            v.enableDanmakuDrawingCache(enable)
        } else {
            userArgs.append({
                view => view.enableDanmakuDrawingCache(enable)
            })
        }
        //        this.delegate.enableDanmakuDrawingCache(enable)
    }

    public func isDanmakuDrawingCacheEnabled(): Bool {
        (this.delegate?.isDanmakuDrawingCacheEnabled()).getOrThrow()
    }

    public override func showFPS(show: Bool): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.showFPS(show)
        } else {
            userArgs.append({
                view => view.showFPS(show)
            })
        }
        //        this.delegate.showFPS(show)
    }

    /**
     * danmaku.isLive == true的情况下,请在非UI线程中使用此方法,避免可能卡住主线程. TODO
     * @param item
     */
    public override func addDanmaku(item: BaseDanmaku): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.addDanmaku(item)
        } else {
            userArgs.append({
                view => view.addDanmaku(item)
            })
        }
        //        this.delegate.addDanmaku(item)
    }

    public override func invalidateDanmaku(item: BaseDanmaku, remeasure: Bool): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.invalidateDanmaku(item, remeasure)
        } else {
            userArgs.append({
                view => view.invalidateDanmaku(item, remeasure)
            })
        }
        //        this.delegate.invalidateDanmaku(item, remeasure)
    }

    public override func removeAllDanmakus(isClearDanmakusOnScreen: Bool): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.removeAllDanmakus(isClearDanmakusOnScreen)
        } else {
            userArgs.append({
                view => view.removeAllDanmakus(isClearDanmakusOnScreen)
            })
        }
        //        this.delegate.removeAllDanmakus(isClearDanmakusOnScreen)
    }

    public override func removeAllLiveDanmakus(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.removeAllLiveDanmakus()
        } else {
            userArgs.append({
                view => view.removeAllLiveDanmakus()
            })
        }
        //        this.delegate.removeAllLiveDanmakus()
    }

    public override func getCurrentVisibleDanmakus(): ?IDanmakus {
        // this.checkDanmakuView()
        return (this.delegate?.getCurrentVisibleDanmakus()).getOrThrow()
    }

    public override func setCallback(callback: DanmakuCallBack): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.setCallback(callback)
        } else {
            userArgs.append({
                view => view.setCallback(callback)
            })
        }
        //        this.delegate.setCallback(callback)
    }

    /**
     * for getting the accurate play-time. use this method instead of parser.getTimer().currMillisecond
     * @return
     */
    public override func getCurrentTime(): Int64 {
        // this.checkDanmakuView()
        return (this.delegate?.getCurrentTime()).getOrThrow()
    }

    public override func getConfig(): ?DanmakuContext {
        // this.checkDanmakuView()
        return (this.delegate?.getConfig()).getOrThrow()
    }

    // ------------- View方法  --------------------
    public override func getView(): IDanmakuView {
        return this
    }

    public func setWidth(width: Int64) {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.setViewWidth(width)
        } else {
            userArgs.append({
                view => view.setViewWidth(width)
            })
        }
        //        this.delegate.setViewWidth(width)
    }

    public func setHeight(height: Int64) {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.setViewHeight(height)
        } else {
            userArgs.append({
                view => view.setViewHeight(height)
            })
        }
        //        this.delegate.setViewHeight(height)
    }

    public override func getWidth(): Int64 {
        // this.checkDanmakuView()
        return (this.delegate?.getViewWidth()).getOrThrow()
    }

    public override func getHeight(): Int64 {
        // this.checkDanmakuView()
        return (this.delegate?.getViewHeight()).getOrThrow()
    }

    public override func setVisibility(visibility: Bool): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.mDanmakuVisible = visibility
        } else {
            userArgs.append({
                view => view.mDanmakuVisible = visibility
            })
        }
        //        this.delegate.mDanmakuVisible = visibility
    }

    public override func isShown(): Bool {
        // this.checkDanmakuView()
        return (this.delegate?.isShown()).getOrThrow()
    }

    // ------------- 播放控制 -------------------

    public override func prepare(parser: BaseDanmakuParser, config: DanmakuContext): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.prepare(parser, config)
        } else {
            userArgs.append({
                view => view.prepare(parser, config)
            })
        }
        //        this.delegate.prepare(parser, config)
    }

    public override func seekTo(ms: Int64): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.seekTo(ms)
        } else {
            userArgs.append({
                view => view.seekTo(ms)
            })
        }
//        this.delegate.seekTo(ms)
    }

    public override func start(): Unit {
        this.start(0)
    }
    public override func start(position: Int64): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.start(position)
        } else {
            userArgs.append({
                view => view.start(position)
            })
        }
//        this.delegate.start(position)
    }

    public override func stop(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.stop()
        } else {
            userArgs.append({
                view => view.stop()
            })
        }
//        this.delegate.stop()
    }

    public override func pause(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.pause()
        } else {
            userArgs.append({
                view => view.pause()
            })
        }
//        this.delegate.pause()
    }

    public override func resume(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.resume()
        } else {
            userArgs.append({
                view => view.resume()
            })
        }
//        this.delegate.resume()
    }

    public override func release(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.release()
        } else {
            userArgs.append({
                view => view.release()
            })
        }
//        this.delegate.release()
    }

    public override func toggle(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.toggle()
        } else {
            userArgs.append({
                view => view.toggle()
            })
        }
//        this.delegate.toggle()
    }

    public override func show(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.show()
        } else {
            userArgs.append({
                view => view.show()
            })
        }
//        this.delegate.show()
    }

    public override func hide(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.hide()
        } else {
            userArgs.append({
                view => view.hide()
            })
        }
//        this.delegate.hide()
    }

    /**
     * show the danmakuview again if you called hideAndPauseDrawTask()
     * @param position The position you want to resume
     * @see #hideAndPauseDrawTask
     */
    public override func showAndResumeDrawTask(position: Int64): Unit {
        // this.checkDanmakuView()
                if (let Some(v) <- this.delegate) {
            v.showAndResumeDrawTask(position)
        } else {
            userArgs.append({
                view => view.showAndResumeDrawTask(position)
            })
        }
//        this.delegate.showAndResumeDrawTask(position)
    }

    /**
     * hide the danmakuview and pause the drawtask
     * @return the paused position
     * @see #showAndResumeDrawTask
     */
    public override func hideAndPauseDrawTask(): Int64 {
        // this.checkDanmakuView()
        return (this.delegate?.hideAndPauseDrawTask()).getOrThrow()
    }

    public override func clearDanmakusOnScreen(): Unit {
        // this.checkDanmakuView()
                if (let Some(v) <- this.delegate) {
            v.clearDanmakusOnScreen()
        } else {
            userArgs.append({
                view => view.clearDanmakusOnScreen()
            })
        }
//        this.delegate.clearDanmakusOnScreen()
    }

    // ------------- Click Listener -------------------
    public override func setOnDanmakuClickListener(listener: OnDanmakuClickListener): Unit {
        // this.checkDanmakuView()
                if (let Some(v) <- this.delegate) {
            v.mOnDanmakuClickListener = listener
        } else {
            userArgs.append({
                view => view.mOnDanmakuClickListener = listener
            })
        }
//        this.delegate.mOnDanmakuClickListener = listener
    }
    public override func setOnDanmakuClickListener(listener: OnDanmakuClickListener, xOff: Float64, yOff: Float64): Unit {
        // this.checkDanmakuView()
                if (let Some(v) <- this.delegate) {
            v.mOnDanmakuClickListener = listener
            v.mXOff = xOff
            v.mYOff = yOff
        } else {
            userArgs.append({view =>
                view.mOnDanmakuClickListener = listener
                view.mXOff = xOff
                view.mYOff = yOff
            })
        }
//        this.delegate.mOnDanmakuClickListener = listener
//        this.delegate.mXOff = xOff
//        this.delegate.mYOff = yOff
    }

    public override func getOnDanmakuClickListener(): OnDanmakuClickListener {
        // this.checkDanmakuView()
        return (this.delegate?.getOnDanmakuClickListener()).getOrThrow()
    }

    public override func getXOff(): Float64 {
        // this.checkDanmakuView()
        return (this.delegate?.getXOff()).getOrThrow()
    }

    public override func getYOff(): Float64 {
        // this.checkDanmakuView()
        return (this.delegate?.getYOff()).getOrThrow()
    }

    public override func forceRender(): Unit {
        // this.checkDanmakuView()
                if (let Some(v) <- this.delegate) {
            v.forceRender()
        } else {
            userArgs.append({
                view => view.forceRender()
            })
        }
//        this.delegate.forceRender()
    }

    public override func isViewReady(): Bool {
        // this.checkDanmakuView()
        return (this.delegate?.isViewReady()).getOrThrow()
    }

    public override func getViewWidth(): Int64 {
        // this.checkDanmakuView()
        return this.getWidth()
    }

    public override func getViewHeight(): Int64 {
        // this.checkDanmakuView()
        return this.getHeight()
    }

    public override func drawDanmakus(): Int64 {
        // this.checkDanmakuView()
        return (this.delegate?.drawDanmakus()).getOrThrow()
    }

    public override func clear(): Unit {
        // this.checkDanmakuView()
        if (let Some(v) <- this.delegate) {
            v.clear()
        } else {
            userArgs.append({
                view => view.clear()
            })
        }
//        this.delegate
    }
}
