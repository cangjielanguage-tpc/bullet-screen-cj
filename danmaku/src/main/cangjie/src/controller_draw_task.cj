/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

let nullConfigChangedCallback  = ConfigChangedCallback({config: DanmakuContext, tag: DanmakuConfigTag, values: Array<Any> =>
        return false
    })

public class DrawTask <: IDrawTask {
  protected var mContext: DanmakuContext
  protected var mDisp: AbsDisplayer<DanmakuCanvas2D, String>
  protected var danmakuList: ?IDanmakus = None

  protected var mParser: ?BaseDanmakuParser = None
  var mTaskListener: TaskListener
  var mRenderer: IRenderer
  var mTimer: DanmakuTimer
  private var danmakus: IDanmakus = Danmakus(ST_BY_LIST)
  protected var clearRetainerFlag: Bool= false
  private var mStartRenderTime: Int64 = 0
  private var mRenderingState: RenderingState = RenderingState()
  protected var mReadyState: Bool = false
  private var mLastBeginMills: Int64 = 0
  private var mLastEndMills: Int64 = 0
  protected var mPlayState: Int64 = 0
  private var mIsHidden: Bool = false
  private var mLastDanmaku: ?BaseDanmaku  = None
  private var mLiveDanmakus: Danmakus = Danmakus(ST_BY_LIST)
  private var mRunningDanmakus: ?IDanmakus = None
  private var mRequestRender: Bool = false
  private var mConfigChangedCallback: ConfigChangedCallback = nullConfigChangedCallback
  public init(timer: DanmakuTimer, context: DanmakuContext, taskListener: TaskListener) {
    this.mContext = context
    this.mDisp = context.getDisplayer()
    this.mTaskListener = taskListener
    let renderer = DanmakuRenderer(context)
    this.mRenderer = renderer
    this.mTimer = timer
    this.mConfigChangedCallback = ConfigChangedCallback ({config: DanmakuContext, tag: DanmakuConfigTag, values: Array<Any> =>
        return this.onDanmakuConfigChanged(config, tag, values)
    })
    renderer.setOnDanmakuShownListener({ danmaku: BaseDanmaku =>
        this.mTaskListener.onDanmakuShown(danmaku)
    })
    renderer.setVerifierEnabled(this.mContext.isPreventOverlappingEnabled() || this.mContext.isMaxLinesLimited())
    if (this.mContext.isDuplicateMergingEnabled()) {
      this.mContext.mDanmakuFilters.registerFilter(DanmakuFilters.TAG_DUPLICATE_FILTER)
    } else {
      this.mContext.mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_DUPLICATE_FILTER)
    }
  }

  protected func initTimer(timer: DanmakuTimer): Unit {
    this.mTimer = timer
  }

  public func addDanmaku(item: BaseDanmaku): Unit {
    if (this.danmakuList.isNone()) {
      return
    }
    if (item.isLive) {
      this.mLiveDanmakus.addItem(item)
      this.removeUnusedLiveDanmakusIn(10)
    }
    item.index = this.danmakuList.getOrThrow().size()
    var subAdded: Bool = true
    if (this.mLastBeginMills <= item.getActualTime() && item.getActualTime() <= this.mLastEndMills) {
      subAdded = this.danmakus.addItem(item)
    } else if (item.isLive) {
      subAdded = false
    }
    var added: Bool = false
    added = this.danmakuList.getOrThrow().addItem(item)
    if (!subAdded || !added) {
      this.mLastBeginMills = 0
      this.mLastEndMills = 0
    }
    if (added) {
      this.mTaskListener.onDanmakuAdd(item)
    }
    if (this.mLastDanmaku.isNone() || item.getActualTime() > this.mLastDanmaku.getOrThrow().getActualTime()) {
      this.mLastDanmaku = item
    }
  }

  public func invalidateDanmaku(item: BaseDanmaku, remeasure: Bool): Unit {
    this.mContext.getDisplayer().getCacheStuffer()?.clearCache(item)
    item.requestFlags |= BaseDanmaku.FLAG_REQUEST_INVALIDATE
    if (remeasure) {
      item.paintWidth = -1.0
      item.paintHeight = -1.0
      item.requestFlags |= BaseDanmaku.FLAG_REQUEST_REMEASURE
      item.measureResetFlag++
    }
  }

  public func removeAllDanmakus(isClearDanmakusOnScreen: Bool): Unit {
    if (this.danmakuList.getOrThrow().isEmpty()){
      return
    }
    if (!isClearDanmakusOnScreen) {
      let beginMills: Int64 = this.mTimer.currMillisecond - this.mContext.mDanmakuFactory.MAX_DANMAKU_DURATION - 100
      let endMills: Int64 = this.mTimer.currMillisecond + this.mContext.mDanmakuFactory.MAX_DANMAKU_DURATION
      if (let Some(v) <- this.danmakuList.getOrThrow().subnew(beginMills, endMills)) {
        this.danmakus = v
      }
    }
    this.danmakuList?.clear()

  }

  protected func onDanmakuRemoved(_: BaseDanmaku): Unit {
    // override by CacheManagingDrawTask
  }

  public func removeAllLiveDanmakus(): Unit {
    if (this.danmakus.isEmpty()) {
      return
    }
    let remove = DefaultConsumer<BaseDanmaku>({danmaku: BaseDanmaku =>
      if (danmaku.isLive) {
        this.onDanmakuRemoved(danmaku)
        return ACTION_REMOVE
      }
        return ACTION_CONTINUE
    })

    this.danmakus.forEachSync(remove)

  }

  protected func removeUnusedLiveDanmakusIn(msec: Int64): Unit {
    if (this.danmakuList.isSome() || this.danmakuList.getOrThrow().isEmpty() || this.mLiveDanmakus.isEmpty()) {
      return
    }
    let startTime = SystemClock.uptimeMillis()
    let removeUnused = DefaultConsumer<BaseDanmaku>({danmaku: BaseDanmaku =>
      let isTimeout: Bool = danmaku.isTimeOut()
      if (SystemClock.uptimeMillis() - startTime > msec) {
        return ACTION_BREAK
      }
      if (isTimeout) {
        this.danmakuList?.removeItem(danmaku)
        this.onDanmakuRemoved(danmaku)
        return ACTION_REMOVE
      } else {
        return ACTION_BREAK
      }
    })
    this.mLiveDanmakus.forEachSync(removeUnused)
  }

  public func getVisibleDanmakusOnTime(time: Int64): IDanmakus {
    let beginMills: Int64 = time - this.mContext.mDanmakuFactory.MAX_DANMAKU_DURATION - 100
    let endMills: Int64 = time + this.mContext.mDanmakuFactory.MAX_DANMAKU_DURATION
    var subDanmakus: ?IDanmakus = None
    var i: Int64 = 0
    while (i < 3) { //avoid ConcurrentModificationException
        i++
        subDanmakus = this.danmakuList.getOrThrow().subnew(beginMills, endMills)
        break
    }
    let visibleDanmakus: IDanmakus = Danmakus()
    if (let Some(v) <- subDanmakus) {
      if (!v.isEmpty()) {
          let subDanMu = DefaultConsumer<BaseDanmaku>({danmaku: BaseDanmaku =>
            if (danmaku.isShown() && !danmaku.isOutside()) {
                visibleDanmakus.addItem(danmaku)
            }
            return ACTION_CONTINUE
          })
          v.forEachSync(subDanMu)
      }
    }
    return visibleDanmakus
  }

    public func draw(displayer: Any): ?RenderingState {
        this.draw((displayer as AbsDisplayer<DanmakuCanvas2D, String>)() )
    }

    func draw(displayer: AbsDisplayer<DanmakuCanvas2D, String>): ?RenderingState {
        return this.drawDanmakus(displayer, this.mTimer)
    }

  public func reset(): Unit {
    this.danmakus = Danmakus()
    this.mRenderer.clear()
  }

  public func seek(mills: Int64): Unit {
    this.reset()
    this.mContext.mGlobalFlagValues.updateVisibleFlag()
    this.mContext.mGlobalFlagValues.updateFirstShownFlag()
    this.mContext.mGlobalFlagValues.updateSyncOffsetTimeFlag()
    this.mContext.mGlobalFlagValues.updatePrepareFlag()
    this.mRunningDanmakus = Danmakus(ST_BY_LIST)
    this.mStartRenderTime = if (mills < 1000) {0} else{mills}
    this.mRenderingState.reset()
    this.mRenderingState.endTime = this.mStartRenderTime
    this.mLastBeginMills = 0
    this.mLastEndMills = 0

    if (this.danmakuList.isSome()) {
      let last: ?BaseDanmaku = this.danmakuList.getOrThrow().last()
      if (let Some(v) <- last) {
        if (v.isTimeOut()) {
          this.mLastDanmaku = v
        }
      }
    }
  }

  public func clearDanmakusOnScreen(currMillis: Int64): Unit {
    this.reset()
    this.mContext.mGlobalFlagValues.updateVisibleFlag()
    this.mContext.mGlobalFlagValues.updateFirstShownFlag()
    this.mStartRenderTime = currMillis
  }

  public func start(): Unit {
    this.mContext.registerConfigChangedCallback(this.mConfigChangedCallback)
  }

  public func quit(): Unit {
    this.mContext.unregisterAllConfigChangedCallbacks()
    this.mRenderer.release()
  }

  public func prepare(): Unit {
    if (this.mParser.isNone()) {
      return
    }
    this.loadDanmakus(this.mParser())
    this.mLastBeginMills = 0
    this.mLastEndMills = 0
    this.mTaskListener.ready()
    this.mReadyState = true
  }

  public func onPlayStateChanged(state: Int64): Unit {
    this.mPlayState = state
  }

  protected func loadDanmakus(parser: BaseDanmakuParser): Unit {
    let that = this
    this.danmakuList = parser.setConfig(this.mContext)
      .setDisplayer(this.mDisp)
      .setTimer(this.mTimer)
      .setListener({danmak =>
          that.mTaskListener.onDanmakuAdd(danmak);
      })
      .getDanmakus()
    that.mContext.mGlobalFlagValues.resetAll()
    if (danmakuList.isSome()) {
      that.mLastDanmaku = that.danmakuList.getOrThrow().last()
    }
  }

  public func setParser(parser: BaseDanmakuParser): Unit {
    this.mParser = parser
    this.mReadyState = false
  }

  protected func drawDanmakus(disp: AbsDisplayer<DanmakuCanvas2D, String>, timer: DanmakuTimer): ?RenderingState {
    if (this.clearRetainerFlag) {
      this.mRenderer.clearRetainer()
      this.clearRetainerFlag = false
    }
    if (this.danmakuList.isSome()) {
      let canvas: DanmakuCanvas2D = disp.getExtraData()
      DrawHelper.clearCanvas(canvas)
      if (this.mIsHidden && !this.mRequestRender) {
        return this.mRenderingState
      }

      this.mRequestRender = false
      let renderingState: RenderingState = this.mRenderingState
      // prepare screenDanmakus
      var beginMills: Int64 = timer.currMillisecond - this.mContext.mDanmakuFactory.MAX_DANMAKU_DURATION - 100  // 16 - 4800 - 100
      var endMills: Int64 = timer.currMillisecond + this.mContext.mDanmakuFactory.MAX_DANMAKU_DURATION
      var screenDanmakus: ?IDanmakus = this.danmakus

      if (this.mLastBeginMills > beginMills || timer.currMillisecond > this.mLastEndMills) {
        screenDanmakus = this.danmakuList.getOrThrow().sub(beginMills, endMills)
        if (let Some(v) <- screenDanmakus) {
          this.danmakus = v
        }
        this.mLastBeginMills = beginMills
        this.mLastEndMills = endMills
      } else {
        beginMills = this.mLastBeginMills
        endMills = this.mLastEndMills
      }
      // prepare runningDanmakus to draw (in sync-mode)
      let runningDanmakus: ?IDanmakus = this.mRunningDanmakus
      this.beginTracing(renderingState, runningDanmakus, screenDanmakus)
      if (let Some(v) <- runningDanmakus) {
        if (!v.isEmpty()) {
          this.mRenderingState.isRunningDanmakus = true
          this.mRenderer.draw(disp, v, 0, this.mRenderingState)
        }
      }
      // draw screenDanmakus
      this.mRenderingState.isRunningDanmakus = false
      if (screenDanmakus.isSome() && !screenDanmakus.getOrThrow().isEmpty()) {
        this.mRenderer.draw(this.mDisp, screenDanmakus.getOrThrow(), this.mStartRenderTime, renderingState)
        this.endTracing(renderingState)
        if (renderingState.nothingRendered) {
          if (let Some(v) <- this.mLastDanmaku ) {
            if (v.isTimeOut()) {
              this.mLastDanmaku = None
              this.mTaskListener.onDanmakusDrawingFinished()
            }
          }
          if (renderingState.beginTime == UNKNOWN_TIME) {
            renderingState.beginTime = beginMills
          }
          if (renderingState.endTime == UNKNOWN_TIME) {
            renderingState.endTime = endMills
          }
        }
        return renderingState
      } else {
        renderingState.nothingRendered = true
        renderingState.beginTime = beginMills
        renderingState.endTime = endMills
        return renderingState
      }
    }
    return None
  }

  public func requestClear(): Unit {
    this.mLastBeginMills = 0
    this.mLastEndMills = 0
    this.mIsHidden = false
  }

  public func requestClearRetainer(): Unit {
    this.clearRetainerFlag = true
  }

  public func requestSync(fromTimeMills: Int64, toTimeMills: Int64, offsetMills: Int64): Unit {
    // obtain the running-danmakus which was drawn on screen
    let runningDanmakus: IDanmakus = this.mRenderingState.obtainRunningDanmakus()
    this.mRunningDanmakus = runningDanmakus
    // set offset time for each running-danmakus
    let running = DefaultConsumer<BaseDanmaku>({danmaku: BaseDanmaku =>
        if (danmaku.isOutside()) {
          return ACTION_REMOVE;
        }
        danmaku.setTimeOffset(offsetMills + danmaku.timeOffset);
        if (danmaku.timeOffset == 0) {
          return ACTION_REMOVE;
        }
        return ACTION_CONTINUE;
      })
    runningDanmakus.forEachSync(running)
    this.mStartRenderTime = toTimeMills
  }

  public func onDanmakuConfigChanged(config: DanmakuContext, tag: DanmakuConfigTag, value: Array<Any>): Bool {
      let handled: Bool = this.handleOnDanmakuConfigChanged(config, tag, value)
      this.mTaskListener.onDanmakuConfigChanged()
      return handled
  }

  protected func handleOnDanmakuConfigChanged(config: DanmakuContext, tag: DanmakuConfigTag, values: Array<Any>): Bool{
    var handled: Bool = false
    if (DanmakuConfigTag.MAXIMUM_NUMS_IN_SCREEN == tag) {
      handled = true
    } else if (DanmakuConfigTag.DUPLICATE_MERGING_ENABLED == tag) {
      if (let Some(v) <- (values[0] as Bool)) {
        if (v) {
          this.mContext.mDanmakuFilters.registerFilter(DanmakuFilters.TAG_DUPLICATE_FILTER )
        } else {
          this.mContext.mDanmakuFilters.unregisterFilter(DanmakuFilters.TAG_DUPLICATE_FILTER)
        }
        handled = true  
      }
    } else if (DanmakuConfigTag.SCALE_TEXTSIZE == tag || DanmakuConfigTag.SCROLL_SPEED_FACTOR == tag || DanmakuConfigTag.DANMAKU_MARGIN == tag) {
      this.requestClearRetainer()
      handled = false
    } else if (DanmakuConfigTag.MAXIMUN_LINES == tag || DanmakuConfigTag.OVERLAPPING_ENABLE == tag) {
      this.mRenderer.setVerifierEnabled(this.mContext.isPreventOverlappingEnabled() || this.mContext.isMaxLinesLimited())
      handled = true
    } else if (DanmakuConfigTag.ALIGN_BOTTOM == tag) {
      if (let Some(v) <- (values[0] as Bool)) {
        this.mRenderer.alignBottom(v)
        handled = true
      }
    }
    return handled
  }

  public func requestHide(): Unit {
    this.mIsHidden = true
  }

  public func requestRender(): Unit {
    this.mRequestRender = true
  }

  private func beginTracing(renderingState: RenderingState, runningDanmakus: ?IDanmakus, screenDanmakus: ?IDanmakus): Unit {
    renderingState.reset()
    renderingState.timer.update(SystemClock.uptimeMillis())
    renderingState.indexInScreen = 0
    renderingState.totalSizeInScreen = 
       if (let Some(v) <- runningDanmakus) {
        v.size()
        } else {
          0
        } + 
        if (let Some(v) <- screenDanmakus) {
        v.size()
        } else {
          0
        }
  }

  private func endTracing(renderingState: RenderingState): Unit {
    renderingState.nothingRendered = (renderingState.totalDanmakuCount == 0)
    if (renderingState.nothingRendered) {
      renderingState.beginTime = UNKNOWN_TIME
    }
    let lastDanmaku: ?BaseDanmaku = renderingState.lastDanmaku
    renderingState.lastDanmaku = None
    renderingState.endTime = 
    if (let Some(v) <- lastDanmaku) {
      v.getActualTime()
    } else {
      UNKNOWN_TIME
    }
    renderingState.consumingTime = renderingState.timer.update(SystemClock.uptimeMillis())
  }
}