/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public interface DanmakuCallBack {
    func prepared(): Unit

    func updateTimer(time: DanmakuTimer): Unit

    func danmakuShown(danmaku: BaseDanmaku): Unit

    func drawingFinished(): Unit
}

public class DrawHandler <: Handler {
    private let classLock: ReentrantMutex = ReentrantMutex()
    private let funcLock = ReentrantMutex()

    var mContext: ?DanmakuContext = None
    private var pausedPosition: Int64 = 0
    private var quitFlag: Bool = true
    private var mTimeBase: Int64 = 0
    private var mReady: Bool = true
    var mCallback: ?DanmakuCallBack = None
    private var timer: DanmakuTimer = DanmakuTimer()
    private var mParser: ?BaseDanmakuParser = None
    public var drawTask: ?IDrawTask = None
    private var mDanmakuView: ?IDanmakuViewController = None
    private var mDanmakusVisible: Bool = true
    private var mDisp: AbsDisplayer<DanmakuCanvas2D, String> = unsafe { zeroValue<AbsDisplayer<DanmakuCanvas2D, String>>(
    ) }
    var mRenderingState: RenderingState = RenderingState()
    private var mDrawTimes: LinkedList<Int64> = LinkedList<Int64>()
    private var mThread: ?Future<Unit> = None
    private var mUpdateInSeparateThread: Bool = false

    private var mCordonTime: Int64 = 30
    private var mCordonTime2: Int64 = 60
    private var mFrameUpdateRate: Int64 = 16
    private var mThresholdTime: Int64 = 0
    private var mLastDeltaTime: Int64 = 0
    private var mInSeekingAction: Bool = true
    private var mDesireSeekingTime: Int64 = 0
    private var mRemainingTime: Int64 = 0
    private var mInSyncAction: Bool = false
    var mInWaitingState: Bool = false
    private var mNonBlockModeEnable: Bool = false
    init(looper: MessageLooper, view: IDanmakuViewController, danmakuVisibile: Bool) {
        super(looper)
        this.bindView(view)
        if (!danmakuVisibile) {
            this.hideDanmakus(false)
        }
        this.mDanmakusVisible = danmakuVisibile
    }

    private func bindView(view: IDanmakuViewController) {
        this.mDanmakuView = view
    }

    public func enableNonBlockMode(enable: Bool): Unit {
        this.mNonBlockModeEnable = enable
    }

    public func setConfig(config: DanmakuContext): Unit {
        this.mContext = config
    }

    public func setParser(parser: BaseDanmakuParser) {
        this.mParser = parser
        if (let Some(time) <- parser.getTimer()) {
            this.timer = timer
        }
    }

    public func setCallback(cb: DanmakuCallBack): Unit {
        this.mCallback = cb
    }

    public func quit(): Unit {
        this.quitFlag = true
        this.sendEmptyMessage(QUIT)
    }

    public func isStop(): Bool {
        return this.quitFlag
    }

    public override func handleMessage(msg: Message): Unit {
        let what: Int64 = msg.what
        match {
            case what == PREPARE => 
                casePREPARE()
            case what == SHOW_DANMAKUS =>
                if (caseSHOW_DANMAKUS(msg)) {
                    caseSTART(msg)
                    caseRESUME()
                }
            case what == START => 
                caseSTART(msg)
                caseRESUME()
            case what == SEEK_POS => 
                caseSEEK_POS(msg)
                caseRESUME()
            case what == RESUME => 
                caseRESUME()
            case what == UPDATE => 
                caseUPDATE()
            case what == NOTIFY_DISP_SIZE_CHANGED => 
                caseNOTIFY_DISP_SIZE_CHANGED(msg)
            case what == HIDE_DANMAKUS => 
                if (caseHIDE_DANMAKUS(msg)) {
                    casePAUSE()
                    caseQUIT(what)
                }
            case what == PAUSE => 
                casePAUSE()
                caseQUIT(what)
            case what == QUIT => 
                caseQUIT(what)
            case what == NOTIFY_RENDERING => 
                this.notifyRendering()
            case what == UPDATE_WHEN_PAUSED => 
                if (this.quitFlag && this.mDanmakuView.isSome()) {
                    this.drawTask?.requestClear()
                    this.mDanmakuView?.drawDanmakus()
                    this.notifyRendering()
                }
            case what == CLEAR_DANMAKUS_ON_SCREEN => 
                this.drawTask?.clearDanmakusOnScreen(this.getCurrentTime())
            case what == FORCE_RENDER => 
                this.drawTask?.requestRender()
            case _ => ()
        }
        
    }

    private func casePREPARE(){
        this.mTimeBase = SystemClock.uptimeMillis()
        if (this.mParser.isNone() || !this.mDanmakuView.getOrThrow().isViewReady()) {
            this.sendEmptyMessageDelayed(PREPARE, 100)
        } else {
            this.prepare({ =>
                    this.pausedPosition = 0
                    this.mReady = true
                    if (let Some(cb) <- this.mCallback) {
                        cb.prepared()
                    }
                })
        }
    }
    private func caseSHOW_DANMAKUS(msg: Message): Bool {
        this.mDanmakusVisible = true
        let start: ?Int64 = msg.obj as Int64
        var resume: Bool = false
        if (let Some(w) <- this.drawTask) {
            if (let Some(v) <- start) {
                w.start()
                w.seek(v)
                w.requestClear()
            } else {
                this.timer.update(this.getCurrentTime())
                w.requestClear()
                resume = true
            }
        }
        if (this.quitFlag) {
            if (let Some(v) <- this.mDanmakuView) {
                v.drawDanmakus()
            }
        }
        this.notifyRendering()
        return resume
    }
    private func caseSTART(msg: Message){
        let startTime: ?Int64 = msg.obj as Int64
        if (let Some(v) <- startTime) {
            this.pausedPosition = v
        } else {
            this.pausedPosition = 0
        }
    }
    private func caseSEEK_POS(msg: Message){
        this.quitFlag = true
        let position: Int64 = (msg.obj as Int64).getOrThrow()
        let deltaMs: Int64 = position - this.timer.currMillisecond
        this.mTimeBase -= deltaMs
        this.timer.update(position)
        this.mContext().mGlobalFlagValues.updateMeasureFlag()
        this.drawTask?.seek(position)
        this.pausedPosition = position
    }
    private func caseRESUME(){
        this.removeMessages(PAUSE)
        this.quitFlag = false
        if (this.mReady) {
            this.mRenderingState.reset()
            this.mDrawTimes.clear()
            this.mTimeBase = SystemClock.uptimeMillis() - this.pausedPosition
            this.timer.update(this.pausedPosition)
            this.removeMessages(RESUME)
            this.sendEmptyMessage(UPDATE)
            this.drawTask().start()
            this.notifyRendering()
            this.mInSeekingAction = false
        // this.drawTask?.onPlayStateChanged(PLAY_STATE_PLAYING)  // 不影响 UI 线程
        } else {
            this.sendEmptyMessageDelayed(RESUME, 100)
        }
    }
    private func caseUPDATE(){
        // 这里是循环开始播放
        this.updateInCurrentThread()
    }
    private func caseNOTIFY_DISP_SIZE_CHANGED(msg: Message){
        this.mContext?.mDanmakuFactory.notifyDispSizeChanged(this.mContext())
        if (let Some(updateFlag) <- (msg.obj as Bool)) {
            if (updateFlag) {
                this.mContext?.mGlobalFlagValues.updateMeasureFlag()
                this.mContext?.mGlobalFlagValues.updateVisibleFlag()
                this.drawTask?.requestClearRetainer()
            }
        }
    }
    private func caseHIDE_DANMAKUS(msg: Message): Bool {
        this.mDanmakusVisible = false
        this.mDanmakuView?.clear()
        this.drawTask?.requestClear()
        this.drawTask?.requestHide()
        let v = (msg.obj as Bool).getOrThrow()
        if (v) {
            this.drawTask?.quit()
        }
        return v
    }
    private func casePAUSE(){
        this.removeMessages(RESUME)
        this.removeMessages(UPDATE)
        this.drawTask?.onPlayStateChanged(PLAY_STATE_PAUSE)
    }
    private func caseQUIT(what: Int64){
        if (what == QUIT) {
            this.removeCallbacksAndMessages()
        }
        this.quitFlag = true
        this.syncTimerIfNeeded()
        this.pausedPosition = this.timer.currMillisecond
        if (what == QUIT) {
            // if (this.drawTask != null) {
            this.drawTask?.quit()
            // }
            // if (this.mParser != null) {
            this.mParser?.release()
            // }
        }
    }

    private func updateInCurrentThread(): Unit {
        if (this.quitFlag) {
            return
        }
        let startMS: Int64 = SystemClock.uptimeMillis()
        var d: Int64 = this.syncTimer(startMS)
        if (d < 0 && !this.mNonBlockModeEnable) {
            this.removeMessages(UPDATE)
            return
        }
        d = this.mDanmakuView().drawDanmakus()
        this.removeMessages(UPDATE)
        if (d > this.mCordonTime2) { // this situation may be cased by ui-thread waiting of DanmakuView, so we sync-timer at once
            this.timer.add(d)
            this.mDrawTimes.clear()
        }
        if (!this.mDanmakusVisible) {
            this.waitRendering(INDEFINITE_TIME)
            return
        } else if (this.mRenderingState.nothingRendered) {
            let dTime: Int64 = this.mRenderingState.endTime - this.timer.currMillisecond
            if (dTime > 500) {
                this.waitRendering(dTime - 10)
                return
            }
        }
        if (d < this.mFrameUpdateRate) {
            this.sendEmptyMessageDelayed(UPDATE, this.mFrameUpdateRate - d)
            return
        }
        this.sendEmptyMessage(UPDATE)
    }

    private func syncTimer(startMS: Int64): Int64 {
        if (this.mInSeekingAction || this.mInSyncAction) {
            return 0
        }
        this.mInSyncAction = true
        var d: Int64 = 0
        let time: Int64 = startMS - this.mTimeBase
        if (this.mNonBlockModeEnable) {
            if (let Some(v) <- this.mCallback) {
                v.updateTimer(this.timer)
                d = this.timer.getLastInterval()
            }
        } else if (!this.mDanmakusVisible || this.mRenderingState.nothingRendered || this.mInWaitingState) {
            this.timer.update(time)
            this.mRemainingTime = 0
            this.mCallback?.updateTimer(this.timer)
        } else {
            var gapTime: Int64 = time - this.timer.currMillisecond
            let averageTime: Int64 = max(this.mFrameUpdateRate, this.getAverageRenderingTime())
            if (gapTime > 2000 || this.mRenderingState.consumingTime > this.mCordonTime || averageTime > this
                .mCordonTime) {
                d = gapTime
                gapTime = 0
            } else {
                d = averageTime + gapTime / this.mFrameUpdateRate
                d = max(this.mFrameUpdateRate, d)
                d = min(this.mCordonTime, d)
                let a: Int64 = d - this.mLastDeltaTime
                if (a > 3 && a < 8 && this.mLastDeltaTime >= this.mFrameUpdateRate && this.mLastDeltaTime <= this
                    .mCordonTime) {
                    d = this.mLastDeltaTime
                }
                gapTime -= d
                this.mLastDeltaTime = d
            }
            this.mRemainingTime = gapTime
            this.timer.add(d)
            this.mCallback?.updateTimer(this.timer)
        }

        this.mInSyncAction = false
        return d
    }

    private func syncTimerIfNeeded(): Unit {
        if (this.mInWaitingState) {
            this.syncTimer(SystemClock.uptimeMillis())
        }
    }

    func initRenderingConfigs(): Unit {
        let averageFrameConsumingTime: Int64 = 16
        this.mCordonTime = Int64(max(33.0, floor(16.0 * 2.5)))
        this.mCordonTime2 = Int64(floor(Float64(this.mCordonTime) * 2.5))
        this.mFrameUpdateRate = max(16, averageFrameConsumingTime / 15 * 15)
        this.mThresholdTime = this.mFrameUpdateRate + 3
    }

    private func prepare(runnable: () -> Unit): Unit {
        if (let Some(v) <- this.drawTask) {
            runnable()
        } else {
            let danmakuView = this.mDanmakuView()
            this.drawTask = this.createDrawTask(danmakuView.isDanmakuDrawingCacheEnabled(), this.timer,
                danmakuView.getViewWidth(), danmakuView.getViewHeight(), Task(this, runnable))
        }
    }

    public func isPrepared(): Bool {
        return this.mReady
    }

    private func createDrawTask(useDrwaingCache: Bool, timer: DanmakuTimer, width: Int64, height: Int64,
        taskListener: TaskListener): IDrawTask {
        this.mDisp = this.mContext.getOrThrow().getDisplayer()
        this.mDisp.setSize(Float64(width), Float64(height))
        this.mDisp.resetSlopPixel(this.mContext.getOrThrow().scaleTextSize)
        let task: IDrawTask = DrawTask(timer, this.mContext(), taskListener)
        task.setParser(this.mParser())
        task.prepare()
        this.sendMessage(Message(what: NOTIFY_DISP_SIZE_CHANGED, obj: false))
        return task
    }

    public func seekTo(ms: Int64): Unit {
        this.mInSeekingAction = true
        this.mDesireSeekingTime = ms
        this.removeMessages(UPDATE)
        this.removeMessages(RESUME)
        this.removeMessages(SEEK_POS)
        this.sendMessage(Message(what: SEEK_POS, obj: ms))
    }

    public func addDanmaku(item: BaseDanmaku): Unit {
        if (this.drawTask.isSome()) {
            item.flags = this.mContext().mGlobalFlagValues
            item.setTimer(this.timer)
            this.drawTask().addDanmaku(item)
            this.sendEmptyMessage(NOTIFY_RENDERING)
        }
    }

    public func invalidateDanmaku(item: BaseDanmaku, remeasure: Bool): Unit {
        this.drawTask?.invalidateDanmaku(item, remeasure)
        this.redrawIfNeeded()
    }

    public func resume(): Unit {
        this.removeMessages(PAUSE)
        this.sendEmptyMessage(RESUME)
    }

    public func prepare(): Unit {
        this.mReady = false
        this.sendEmptyMessage(PREPARE)
    }

    public func pause(): Unit {
        this.removeMessages(RESUME)
        this.syncTimerIfNeeded()
        this.sendEmptyMessage(PAUSE)
    }

    public func showDanmakus(position: Int64): Unit {
        if (this.mDanmakusVisible) {
            return
        }
        this.mDanmakusVisible = true
        this.removeMessages(SHOW_DANMAKUS)
        this.removeMessages(HIDE_DANMAKUS)
        this.sendMessage(Message(what: SHOW_DANMAKUS, obj: position))
    }

    public func hideDanmakus(quitDrawTask: Bool): Int64 {
        if (!this.mDanmakusVisible) {
            return this.timer.currMillisecond
        }
        this.mDanmakusVisible = false
        this.removeMessages(SHOW_DANMAKUS)
        this.removeMessages(HIDE_DANMAKUS)
        this.sendMessage(Message(what: HIDE_DANMAKUS, obj: quitDrawTask))
        return this.timer.currMillisecond
    }

    public func forceRender(): Unit {
        this.removeMessages(FORCE_RENDER)
        this.sendEmptyMessage(FORCE_RENDER)
    }

    public func getVisibility(): Bool {
        return this.mDanmakusVisible
    }

    public func draw(canvas: DanmakuCanvas2D): RenderingState {
        if (this.drawTask.isNone()) {
            return this.mRenderingState
        }
        if (!this.mInWaitingState) {
            if (let Some(danmakuSync) <- this.mContext().danmakuSync) {
                do {
                    let isSyncPlayingState: Bool = danmakuSync.isSyncPlayingState()
                    if (!isSyncPlayingState && this.quitFlag) {
                        break
                    }
                    let syncState: Int64 = danmakuSync.getSyncState()
                    if (syncState == AbsDanmakuSync.SYNC_STATE_PLAYING) {
                        let fromTime: Int64 = this.timer.currMillisecond
                        let toTime: Int64 = danmakuSync.getUptimeMillis()
                        let offset: Int64 = toTime - fromTime
                        if (abs(offset) > danmakuSync.getThresholdTimeMills()) {
                            if (isSyncPlayingState && this.quitFlag) {
                                this.resume()
                            }
                            this.drawTask?.requestSync(fromTime, toTime, offset)
                            this.timer.update(toTime)
                            this.mTimeBase -= offset
                            this.mRemainingTime = 0
                        }
                    } else if (syncState == AbsDanmakuSync.SYNC_STATE_HALT) {
                        if (isSyncPlayingState && !this.quitFlag) {
                            this.pause()
                        }
                    }
                } while (false)
            }
        }
        this.mDisp.setExtraData(canvas)
        this.mRenderingState.set(this.drawTask().draw(this.mDisp))
        this.recordRenderingTime()
        return this.mRenderingState
    }

    func redrawIfNeeded(): Unit {
        if (this.quitFlag && this.mDanmakusVisible) {
            this.removeMessages(UPDATE_WHEN_PAUSED)
            this.sendEmptyMessageDelayed(UPDATE_WHEN_PAUSED, 100)
        }
    }

    func notifyRendering(): Unit {
        if (!this.mInWaitingState) {
            return
        }
        if (let Some(v) <- this.drawTask) {
            v.requestClear()
        }
        if (this.mUpdateInSeparateThread) {
            synchronized(this.classLock) {
                this.mDrawTimes.clear()
            }
        // TODO 异步线程更新
        // synchronized (drawTask) {
        //           drawTask.notifyAll();
        //       }
        } else {
            synchronized(this.classLock) {
                this.mDrawTimes.clear()
            }
            this.removeMessages(UPDATE)
            this.sendEmptyMessage(UPDATE)
        }
        this.mInWaitingState = false
    }

    private func waitRendering(dTime: Int64): Unit {
        if (this.isStop() || !this.isPrepared() || this.mInSeekingAction) {
            return
        }
        this.mRenderingState.sysTime = SystemClock.uptimeMillis()
        this.mInWaitingState = true
        if (dTime == INDEFINITE_TIME) {
            this.removeMessages(NOTIFY_RENDERING)
            this.removeMessages(UPDATE)
        } else {
            this.removeMessages(NOTIFY_RENDERING)
            this.removeMessages(UPDATE)
            this.sendEmptyMessageDelayed(NOTIFY_RENDERING, dTime)
        }
    }

    private func getAverageRenderingTime(): Int64 {
        synchronized(this.classLock) {
            let frames: Int64 = this.mDrawTimes.size
            if (frames <= 0) {
                return 0
            }
            let first: ?Int64 = this.mDrawTimes.first
            let last: ?Int64 = this.mDrawTimes.last
            if (let Some(v) <- first) {
                if (let Some(m) <- last) {
                    let dtime: Int64 = m - v
                    return dtime / frames
                }
            }
            return 0
        }
    }

    private func recordRenderingTime(): Unit {
        synchronized(this.classLock) {
            let lastTime: Int64 = SystemClock.uptimeMillis()
            this.mDrawTimes.append(lastTime)
            var frames = this.mDrawTimes.size
            if (frames > MAX_RECORD_SIZE) {
                this.mDrawTimes.popFirst()
                frames = MAX_RECORD_SIZE
            }
        }
    }

    public func getDisplayer(): IDisplayer {
        return this.mDisp
    }

    public func notifyDispSizeChanged(width: Float64, height: Float64): Unit {
        // if (this.mDisp == null) {
        //   return
        // }
        if (this.mDisp.getWidth() != width || this.mDisp.getHeight() != height) {
            this.mDisp.setSize(width, height)
            this.sendMessage(Message(what: NOTIFY_DISP_SIZE_CHANGED, obj: true))
        }
    }

    public func removeAllDanmakus(isClearDanmakusOnScreen: Bool): Unit {
        // if (this.drawTask != null) {
        this.drawTask?.removeAllDanmakus(isClearDanmakusOnScreen)
        // }
    }

    public func removeAllLiveDanmakus(): Unit {
        // if (this.drawTask != null) {
        this.drawTask?.removeAllLiveDanmakus()
        // }
    }

    public func getCurrentVisibleDanmakus(): ?IDanmakus {
        if (this.drawTask.isSome()) {
            return this.drawTask().getVisibleDanmakusOnTime(this.getCurrentTime())
        }

        return None
    }

    public func getCurrentTime(): Int64 {
        if (!this.mReady) {
            return 0
        }
        if (this.mInSeekingAction) {
            return this.mDesireSeekingTime
        }
        if (this.quitFlag || !this.mInWaitingState) {
            return this.timer.currMillisecond - this.mRemainingTime
        }
        return SystemClock.uptimeMillis() - this.mTimeBase
    }

    public func clearDanmakusOnScreen(): Unit {
        this.sendEmptyMessage(CLEAR_DANMAKUS_ON_SCREEN)
    }

    public func getConfig(): ?DanmakuContext {
        return this.mContext
    }
}
