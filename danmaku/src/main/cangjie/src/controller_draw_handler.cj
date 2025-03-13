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
    private let mDanmakuView: DanmakuView
    private var mDanmakusVisible: Bool = true
    private var mDisp: ?AbsDisplayer<DanmakuCanvas2D, String> = None
    var mRenderingState: RenderingState = RenderingState()
    private var mDrawTimes: LinkedList<Int64> = LinkedList<Int64>()
    private var mThread: ?Future<Unit> = None // TODO see
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
    var mPauseState: ?Bool = None
    private var mNonBlockModeEnable: Bool = false

    var backAnimator: AnimatorResult = unsafe {zeroValue<AnimatorResult>()}

    init(looper: MessageLooper, view: DanmakuView, danmakuVisibile: Bool) {
        super(looper)
        this.mDanmakuView = view
        if (!danmakuVisibile) {
            this.hideDanmakus(false)
        }
        this.mDanmakusVisible = danmakuVisibile
        this.backAnimator = AnimatorResult(AnimatorOptions(
                          duration: 5000,
                          easing: "ease",
                          delay: 13,
                          fill: AnimatorFill.None,
                          direction: AnimatorDirection.Normal,
                          iterations: -1,
                          begin: 0.0,
                          end: 1.0
                        ))
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
        this.caseQUIT(QUIT)
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
                if (this.quitFlag) {
                    this.drawTask?.requestClear()
                    this.mDanmakuView.drawDanmakus()
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
        if (this.mParser.isNone() || !this.mDanmakuView.isViewReady()) {
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
            this.mDanmakuView.drawDanmakus()
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
        this.backAnimator.play()
    }
    private func caseSEEK_POS(msg: Message){
        this.quitFlag = true
        let position: Int64 = (msg.obj as Int64).getOrThrow()
        let deltaMs: Int64 = position - this.timer.currMillisecond
        this.mTimeBase -= deltaMs
        this.timer.update(position)
        this.mContext?.mGlobalFlagValues.updateMeasureFlag()
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
            this.notifyRendering()
            this.mInSeekingAction = false
        } else {
            this.sendEmptyMessageDelayed(RESUME, 100)
        }
        if (let Some(v) <- this.mPauseState) {
            if (!v) {
                return
            }
        }
        this.backAnimator.play()
        this.mPauseState = false
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
        this.mDanmakuView.clear()
        this.drawTask?.requestClear()
        this.drawTask?.requestHide()
        let v = (msg.obj as Bool).getOrThrow()
        if (v) {
            this.drawTask?.quit()
        }
        return v
    }
    private func casePAUSE(){  // 暂停时 TODO
        this.removeMessages(RESUME)
        if (let Some(v) <- this.mPauseState) {
            if (!v) {
                this.backAnimator.pause()
                this.mPauseState = true
            }
        } else {
            this.backAnimator.pause()
            this.mPauseState = true
        }
    }

    private func caseQUIT(what: Int64){
        if (what == QUIT) {
            this.removeCallbacksAndMessages()
        }
        this.quitFlag = true
        this.syncTimerIfNeeded()
        this.pausedPosition = this.timer.currMillisecond
        if (what == QUIT) {
            this.drawTask?.quit()
            this.mParser?.release()
        }
        this.backAnimator.finish()
    }

    private func updateInCurrentThread(): Unit {
        if (this.quitFlag) {
            return
        }
        let startMS: Int64 = SystemClock.uptimeMillis()
        var d: Int64 = this.syncTimer(startMS)
        if (d < 0 && !this.mNonBlockModeEnable) {
            return
        }
        d = this.mDanmakuView.drawDanmakus()
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
            let danmakuView = this.mDanmakuView
            this.drawTask = this.createDrawTask(danmakuView.isDanmakuDrawingCacheEnabled(), this.timer,
                danmakuView.getViewWidth(), danmakuView.getViewHeight(), Task(this, runnable))
        }
        this.backAnimator.onframe = { _ =>
                this.updateInCurrentThread()
            }
    }

    public func isPrepared(): Bool {
        return this.mReady
    }

    private func createDrawTask(useDrwaingCache: Bool, timer: DanmakuTimer, width: Float64, height: Float64,
        taskListener: TaskListener): IDrawTask {
        this.mDisp = this.mContext.getOrThrow().getDisplayer()
        this.mDisp?.setSize(width, height)
        this.mDisp?.resetSlopPixel(this.mContext.getOrThrow().scaleTextSize)
        let task: IDrawTask = DrawTask(timer, this.mContext(), taskListener)
        task.setParser(this.mParser())
        task.prepare()
        obtainMessage(NOTIFY_DISP_SIZE_CHANGED, false).sendToTarget()
        return task
    }

    public func seekTo(ms: Int64): Unit {
        this.mInSeekingAction = true
        this.mDesireSeekingTime = ms
        this.removeMessages(RESUME)
        this.removeMessages(SEEK_POS)
        obtainMessage(SEEK_POS, ms).sendToTarget()
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
        obtainMessage(SHOW_DANMAKUS, position).sendToTarget()
    }

    public func hideDanmakus(quitDrawTask: Bool): Int64 {
        if (!this.mDanmakusVisible) {
            return this.timer.currMillisecond
        }
        this.mDanmakusVisible = false
        this.removeMessages(SHOW_DANMAKUS)
        this.removeMessages(HIDE_DANMAKUS)
        obtainMessage(HIDE_DANMAKUS, quitDrawTask).sendToTarget()
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
        this.mDisp?.setExtraData(canvas)

        this.mRenderingState.set(this.drawTask().draw(this.mDisp.getOrThrow())) //TODO 类型判断
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
        } else {
            synchronized(this.classLock) {
                this.mDrawTimes.clear()
            }
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
        } else {
            this.removeMessages(NOTIFY_RENDERING)
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
        return this.mDisp.getOrThrow()
    }

    public func notifyDispSizeChanged(width: Float64, height: Float64): Unit {
         if (this.mDisp.isNone()) {
           return
         }
        if (this.mDisp.getOrThrow().getWidth() != width || this.mDisp.getOrThrow().getHeight() != height) {
            this.mDisp?.setSize(width, height)
            obtainMessage(NOTIFY_DISP_SIZE_CHANGED, true).sendToTarget()
        }
    }

    public func removeAllDanmakus(isClearDanmakusOnScreen: Bool): Unit {
        this.drawTask?.removeAllDanmakus(isClearDanmakusOnScreen)
    }

    public func removeAllLiveDanmakus(): Unit {
        this.drawTask?.removeAllLiveDanmakus()
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
            return max(this.timer.currMillisecond - this.mRemainingTime, 0)
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
