/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

import ohos.state_macro_manage.*

var pxTovp: Float64 = 3.25
let MAX_RECORD_SIZE: Int64 = 50
let ONE_SECOND: Int64 = 1000

let DefaultDanmakuViewModel = DanmakuViewModel()

@Component
public class DanmakuView {
    @Link
    var model: DanmakuViewModel = DefaultDanmakuViewModel
    @State
    var refreshGeneration: Int64 = 0
    private let settings: RenderingContextSettings = RenderingContextSettings(antialias: true)
    let context: DanmakuCanvas2D = DanmakuCanvas2D(CanvasRenderingContext2D(this.settings))
    var ready: Bool = false
    @State
    @Watch[onRelayout]
    var viewWidth: Float64 = lpx2px(720.lpx).getOrThrow().value
    @State
    @Watch[onRelayout]
    var viewHeight: Float64 = lpx2px(720.lpx).getOrThrow().value

    var mHandlerThread: ?HandlerThread = None

    @State
    var mbackgroundColor: Color = Color.BLACK

    var mCallback: ?DanmakuCallBack = None
    var handler_: ?DrawHandler = None
    prop handler: DrawHandler {
        get () {
            return handler_.getOrThrow()
        }
    }

    var mEnableDanmakuDrwaingCache: Bool = false

    var mOnDanmakuClickListener: ?OnDanmakuClickListener = None
    var mXOff: Float64 = 0.0
    var mYOff: Float64 = 0.0
    var mTouchHelper: ?DanmakuTouchHelper = None
    var mShowFps: Bool = false
    var mDanmakuVisible: Bool = true
    var mDrawingThreadType: Int64 = THREAD_TYPE_NORMAL_PRIORITY
    var mRequestRender: Bool = false
    var mDrawTimes: NonBlockingQueue<Int64> = NonBlockingQueue<Int64>()
    var mClearFlag: Bool = false

    let mResumeRunnable: RunnableRecords = RunnableRecords()

    func invalidate(): Unit {
        this.onDraw(this.context)
    }

    func postInvalidate(): Unit {
        this.invalidate()
    }

    func setViewWidth(w: Float64): Unit {
        this.viewWidth = w
        this.context.width_ = w
    }
    func getViewWidth(): Float64 {
        this.viewWidth
    }
    func setViewHeight(h: Float64): Unit {
        this.viewHeight = h
        this.context.height_ = h
    }
    func getViewHeight(): Float64 {
        this.viewHeight
    }

    func backgroundColor(color: UInt32): DanmakuView {
        this.mbackgroundColor = Color(color)
        this
    }
    func backgroundColor(color: Color): DanmakuView {
        this.mbackgroundColor = color
        this
    }

    protected func aboutToAppear() {
        this.model.setDanmakuView(this)
        this.initialize(this.model)
        let that = this
        let call = {
            =>
            if (that.handler_.isNone()) {
                return
            }
            let drawHandler: DrawHandler = that.handler
            drawHandler.resume()
        }
        this.mResumeRunnable.setCall(call)
    }

    private func initialize(danmakuView: IDanmakuView): Unit {
        DrawHelper.useDrawColorToClearCanvas(true, false)
        this.mTouchHelper = DanmakuTouchHelper.instance(danmakuView)
    }

    func pxTovpRes(): Bool {
        let optValue: Float64 = 55.0
        let res = px2vp(optValue.px).getOrThrow().value
        pxTovp = optValue / res
        return true
    }

    @Builder
    func setSvgCanvas(b: Bool) {
        Canvas(this.context.getContext())
            .onReady({
                =>
                    this.ready = true
                    if (b) {
                    	this.context.setWidthHeight(viewWidth / pxTovp , viewHeight / pxTovp)
                    }
            })
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(Color.TRANSPARENT)
            .onDisAppear({=>
                this.release()
                this.context.reset()
                this.stopDraw()
                Message.release()
            })
    }

    func build() {
        Stack() {
            setSvgCanvas(pxTovpRes())
        }
        .backgroundColor(this.mbackgroundColor)
        .width(model.getWidth().px)
        .height(model.getHeight().px)
        .visibility(getVisible(this.mDanmakuVisible))
        .onTouch({
            event => this.onTouchEvent(event)
        })
    }

    func getVisible(b: Bool): Visibility {
        if (b) {
            return Visibility.Visible
        } else {
            return Visibility.Hidden
        }
    }

    /**
     * danmaku.isLive == true的情况下,请在非UI线程中使用此方法,避免可能卡住主线程
     *
     * @param item
     */
    func addDanmaku(item: BaseDanmaku): Unit { // from IDanmakuView
        if (item.getType() <= BaseDanmaku.TYPE_SPECIAL) {
            item.text = item.text.replace("\r", "\\r").replace("\n", "\\n")
        }
        this.handler.addDanmaku(item)
    }

    func invalidateDanmaku(item: BaseDanmaku, remeasure: Bool): Unit { // from IDanmakuView
            this.handler.invalidateDanmaku(item, remeasure)
    }

    func removeAllDanmakus(isClearDanmakusOnScreen: Bool): Unit { // from IDanmakuView
            this.handler.removeAllDanmakus(isClearDanmakusOnScreen)
    }

    func removeAllLiveDanmakus(): Unit { // from IDanmakuView
            this.handler.removeAllLiveDanmakus()
    }

    func getCurrentVisibleDanmakus(): ?IDanmakus { // from IDanmakuView
        return this.handler.getCurrentVisibleDanmakus()
    }

    func setCallback(callback: DanmakuCallBack): Unit { // from IDanmakuView
        this.mCallback = callback
            this.handler.setCallback(callback)
    }

    func release(): Unit { // from IDanmakuView 播放控制
        this.stopDraw()
    }

    func stop(): Unit { // from IDanmakuView 播放控制
        this.stopDraw()
    }

    func stopDraw(): Unit {
        if (this.handler_.isNone()) {
            return
        }
        this.handler.quit()
        if (let Some(v) <- this.mHandlerThread) {
            v.quit()
            this.mHandlerThread = None
        }
    }

    func getLooper(priority: Int32): MessageLooper {
        if (let Some(v) <- this.mHandlerThread) {
            v.quit()
            this.mHandlerThread = None
        }
        let mht = HandlerThread("DFM Handler Thread #", priority)
        mht.run()
        let loop = mht.getLooper().getOrThrow()
        this.mHandlerThread = mht
        return loop
    }

    func prepareInner(): Unit {
        if (this.handler_.isNone()) {
            this.handler_ = DrawHandler(getLooper(0), this, this.mDanmakuVisible)
        }
    }

    func prepare(parser: BaseDanmakuParser, config: DanmakuContext): Unit { // from IDanmakuView 播放控制
        this.prepareInner()
        this.handler.setConfig(config)
        this.handler.setParser(parser)
        if (let Some(v) <- this.mCallback) {
            this.handler.setCallback(v)
        }
        this.handler.prepare()
    }

    func isPrepared(): Bool { // from IDanmakuView
        return this.handler_.isSome() && this.handler.isPrepared()
    }

    func getConfig(): ?DanmakuContext { // from IDanmakuView
        return this.handler.getConfig()
    }

    func showFPS(show: Bool): Unit { // from IDanmakuView
        this.mShowFps = show
    }

    func fps(): Float64 {
        let lastTime: Int64 = SystemClock.uptimeMillis()
        this.mDrawTimes.enqueue(lastTime)
        if (let Some(first) <- this.mDrawTimes.head()) {
            let dtime: Int64 = lastTime - first
            let frames: Int64 = this.mDrawTimes.size
            if (frames > MAX_RECORD_SIZE) {
                this.mDrawTimes.dequeue()
            }
            if (dtime > 0) {
                return Float64(this.mDrawTimes.size * ONE_SECOND) / Float64(dtime)
            }
        }
        return 0.0
    }

    func drawDanmakus(): Int64 { // from IDanmakuViewController
        if (!this.isShown()) {
            return -1
        }
        let stime: Int64 = SystemClock.uptimeMillis()
        this.lockCanvas()
        return SystemClock.uptimeMillis() - stime
    }

    func postInvalidateCompat(): Unit {
        this.mRequestRender = true
        this.postInvalidate()
    }

    func lockCanvas(): Unit {
        if (this.mDanmakuVisible == false) {
            return
        }
        this.postInvalidateCompat()
    }

    func onDraw(canvas: DanmakuCanvas2D): Int64 {
        if (!this.ready) {
            return 0
        }
        if ((!this.mDanmakuVisible) && (!this.mRequestRender)) {
            return 0
        }
        // TODO 定位安卓和ets调用差异        DrawHelper.clearCanvas(canvas)
        if (this.mClearFlag) {
            DrawHelper.clearCanvas(canvas)
            this.mClearFlag = false
        } else {
            this.handler.draw(canvas)
            if (this.mShowFps) {
                let fps: String = "fps ${this.fps().format('.2')}, time:${this.getCurrentTime() / 1000} s"
                DrawHelper.drawFPS(canvas, fps)
            }
        }
        this.mRequestRender = false
        return 0
    }

    func onRelayout(): Unit {
            this.handler.notifyDispSizeChanged(Float64(this.viewWidth), Float64(this.viewHeight))
    }

    func toggle(): Unit { // from IDanmakuView 播放控制
        if (this.handler_.isNone()) {
            this.start()
        } else if (this.handler.isStop()) {
            this.resume()
        } else {
            this.pause()
        }
    }

    func pause(): Unit { // from IDanmakuView 播放控制
        this.handler.removeCallbacks(this.mResumeRunnable)
        this.handler.pause()
    }

    func resume(): Unit { // from IDanmakuView 播放控制
        if (this.handler_.isSome() && this.handler.isPrepared()) {
            this.handler.post(this.mResumeRunnable)
        } else if (this.handler_.isNone()) {
            this.restart()
        }
    }

    func isPaused(): Bool { // from IDanmakuView
        if (this.handler_.isSome()) {
            return this.handler.isStop()
        }
        return false
    }

    func restart(): Unit {
        this.stop()
        this.start()
    }

    func start(): Unit {
        this.start(0)
    }
    func start(position: Int64): Unit { // from IDanmakuView 播放控制
        if (this.handler_.isNone()) {
            this.prepareInner()
        } else {
            this.handler.removeCallbacksAndMessages()
        }
        this.handler.sendMessage(Message(what: START, obj: position))
    }

    func onTouchEvent(event: TouchEvent): Unit {
        this.mTouchHelper?.onTouchEvent(event)
    }

    func seekTo(ms: Int64): Unit { // from IDanmakuView 播放控制
        if (this.handler_.isSome()) {
            this.handler.seekTo(ms)
        }
    }

    func isViewReady(): Bool { // from IDanmakuViewController
        return this.ready
    }

    func show(): Unit { // from IDanmakuView 播放控制
        this.showAndResumeDrawTask(0)
    }

    /**
     * show the danmakuview again if you called hideAndPauseDrawTask()
     *
     * @param position The positionhPoints.push you want to resume
     * @see #hideAndPauseDrawTask
     */
    func showAndResumeDrawTask(position: Int64): Unit { // from IDanmakuView 播放控制
        this.mDanmakuVisible = true
        this.mClearFlag = false
        if (this.handler_.isNone()) {
            return
        }
        this.handler.showDanmakus(position)
    }

    func hide(): Unit { // from IDanmakuView 播放控制
        this.mDanmakuVisible = false
        if (this.handler_.isNone()) {
            return
        }
        this.handler.hideDanmakus(false)
    }

    /**
     * hide the danmakuview and pause the drawtask
     *
     * @return the paused position
     * @see #showAndResumeDrawTask
     */
    func hideAndPauseDrawTask(): Int64 { // from IDanmakuView 播放控制
        this.mDanmakuVisible = false
        if (this.handler_.isNone()) {
            return 0
        }
        return this.handler.hideDanmakus(true)
    }

    func clear(): Unit { // from IDanmakuViewController
        if (!this.isViewReady()) {
            return
        }
        this.mClearFlag = true
        this.postInvalidateCompat()
    }

    func isShown(): Bool { // from IDanmakuView View方法
        return this.mDanmakuVisible
    }

    /**
     * @param type One of THREAD_TYPE_MAIN_THREAD, THREAD_TYPE_HIGH_PRIORITY, THREAD_TYPE_NORMAL_PRIORITY, or THREAD_TYPE_LOW_PRIORITY.
     */
    func setDrawingThreadType(threadType: Int64): Unit { // from IDanmakuView
        this.mDrawingThreadType = threadType
    }

    public func enableDanmakuDrawingCache(enable: Bool): Unit {
        this.mEnableDanmakuDrwaingCache = enable
    }

    public func isDanmakuDrawingCacheEnabled(): Bool {
        this.mEnableDanmakuDrwaingCache
    }

    /**
     * for getting the accurate play-time. use this method instead of parser.getTimer().currMillisecond
     *
     * @return
     */
    func getCurrentTime(): Int64 { // from IDanmakuView
        return this.handler.getCurrentTime()
    }

    func clearDanmakusOnScreen(): Unit {
        this.handler.clearDanmakusOnScreen()
    }

    func getOnDanmakuClickListener(): ?OnDanmakuClickListener { // from IDanmakuView Click Listener
        return this.mOnDanmakuClickListener
    }

    func getXOff(): Float64 { // from IDanmakuView Click Listener
        return this.mXOff
    }

    func getYOff(): Float64 { // from IDanmakuView Click Listener
        return this.mYOff
    }

    func forceRender(): Unit { // from IDanmakuView Click Listener
        this.mRequestRender = true
        this.handler.forceRender()
    }

    func setBackgroundColor(color: Color): Unit {
        this.mbackgroundColor = color
    }
}
