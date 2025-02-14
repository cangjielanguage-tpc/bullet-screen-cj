/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

class InnerVerifier <: Verifier {
    static let NULL_CLASS = unsafe {zeroValue<InnerVerifier>()}  // 一定初始化， 不用处理
    private let self: DanmakuRenderer
    init(self: DanmakuRenderer) {
        this.self = self
    }
    public override func skipLayout(danmaku: BaseDanmaku, fixedTop: Float64, lines: Int64, willHit: Bool): Bool {
        if (danmaku.priority == 0 && self.mContext.mDanmakuFilters.filterSecondary(danmaku, lines, 0, self.mStartTimer.getOrThrow(),
            willHit, self.mContext)) {
            danmaku.setVisibility(false)
            return true
        }
        return false
    }
}

public class DanmakuRenderer <: Renderer {
    var mStartTimer: ?DanmakuTimer = None
    var mContext: DanmakuContext
    var mVerifier: ?Verifier = Option<Verifier>.None
    private var verifier: Verifier
    var mDanmakusRetainer: Option<DanmakusRetainer> = Option<DanmakusRetainer>.None
    var mOnDanmakuShownListener: Option<(BaseDanmaku) -> Unit> = None
    private var mConsumer: InnerConsumer

    public init(config: DanmakuContext) {
        super()
        mContext = config
        this.verifier = InnerVerifier.NULL_CLASS
        this.mConsumer = InnerConsumer.NULL_CLASS
        this.verifier = InnerVerifier(this)
        this.mConsumer = InnerConsumer(this)
        mDanmakusRetainer = DanmakusRetainer(config.isAlignBottom())
    }

    public func clear(): Unit {
        clearRetainer()
        mContext.mDanmakuFilters.clear()
    }

    public func clearRetainer(): Unit {
        if (let Some(v) <- mDanmakusRetainer) {
            v.clear()
        }
    }

    public func release(): Unit {
        if (let Some(v) <- mDanmakusRetainer) {
            v.release()
        }
        mContext.mDanmakuFilters.clear()
    }

    public func setVerifierEnabled(enabled: Bool): Unit {
        mVerifier = if (enabled) {
            verifier
        } else {
            None
        }
    }

    public func draw(disp: IDisplayer, danmakus: IDanmakus, startRenderTime: Int64, renderingState: RenderingState): Unit {
        mStartTimer = renderingState.timer
       mConsumer.disp = disp
       mConsumer.renderingState = renderingState
       mConsumer.startRenderTime = startRenderTime
        danmakus.forEachSync(mConsumer)
    }

    public func setOnDanmakuShownListener(onDanmakuShown: (BaseDanmaku) -> Unit): Unit {
        mOnDanmakuShownListener = onDanmakuShown
    }

    public func removeOnDanmakuShownListener(): Unit {
        mOnDanmakuShownListener = None
    }

    public func alignBottom(enable: Bool): Unit {
        if (let Some(v) <- mDanmakusRetainer) {
            v.setAlignBottom(enable)
        }
    }
}

class InnerConsumer <: Consumer<BaseDanmaku, Unit> {
    static let NULL_CLASS = unsafe {zeroValue<InnerConsumer>()}// 一定初始化， 不用处理
    private var lastItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var disp: ?IDisplayer = None
    public var renderingState: ?RenderingState = Option<RenderingState>.None
    public var startRenderTime: Int64 = 0
    private let self: DanmakuRenderer

    init(self: DanmakuRenderer) {
        this.self = self
    }

    public override func accept(drawItem: BaseDanmaku): Int64 {
        lastItem = drawItem
        if (drawItem.isTimeOut()) {
            disp?.recycle(drawItem)
            if (let Some(v) <- renderingState) {
                return if (v.isRunningDanmakus) {
                    ACTION_REMOVE
                } else {
                    ACTION_CONTINUE
                }
            }
        }
        if (let Some(v) <- renderingState) {
            if (!v.isRunningDanmakus && drawItem.isOffset()) {
                return ACTION_CONTINUE
            }
        }
        if (let Some(v) <- renderingState) {
            if (!drawItem.hasPassedFilter()) { //还没执行过过滤逻辑
                self.mContext.mDanmakuFilters.filter(drawItem, v.indexInScreen, v.totalSizeInScreen, v.timer, false,
                    self.mContext)
            }
        }
        if (drawItem.getActualTime() < startRenderTime
            || (drawItem.priority == 0 && drawItem.isFiltered())) { // isFiltered 就表示已经被过滤掉了 0表示低优先级 大于0不会被过滤
            return ACTION_CONTINUE
        }

//        if (drawItem.isLate()) {
//            return ACTION_BREAK
//        }

        if (drawItem.getType() == BaseDanmaku.TYPE_SCROLL_RL) {
            // 同屏弹幕密度只对滚动弹幕有效
            if (let Some(v) <- renderingState) {
                v.indexInScreen++
            }
        }

        // measure
        if (!drawItem.isMeasured()) {
            drawItem.measure(disp.getOrThrow(), false)
        }

        // notify prepare drawing
        if (!drawItem.isPrepared()) {
            drawItem.prepare(disp.getOrThrow(), false)
        }

        // layout
        if (let Some(v) <- self.mDanmakusRetainer) {
            v.fix(drawItem, disp.getOrThrow(), self.mVerifier)
        }

        // draw
        if (drawItem.isShown()) {
            if (drawItem.lines.isNone() && drawItem.getBottom() > disp.getOrThrow().getHeight()) {
                return ACTION_CONTINUE // skip bottom outside danmaku
            }
            let renderingType: Int64 = drawItem.draw(disp.getOrThrow())
            if (let Some(v) <- renderingState) {
                if (renderingType == CACHE_RENDERING) {
                    v.cacheHitCount++
                } else if (renderingType == TEXT_RENDERING) {
                    v.cacheMissCount++
                }
                v.addCount(drawItem.getType(), 1)
                v.addTotalCount(1)
                v.appendToRunningDanmakus(drawItem)
            }
            if (let Some(v) <- self.mOnDanmakuShownListener) {
                if (drawItem.firstShownFlag != self.mContext.mGlobalFlagValues.FIRST_SHOWN_RESET_FLAG) {
                    drawItem.firstShownFlag = self.mContext.mGlobalFlagValues.FIRST_SHOWN_RESET_FLAG
                    v(drawItem)
                }
            }
        }
        return ACTION_CONTINUE
    }

    public override func after(): Unit {
        if (let Some(v) <- renderingState) {
            v.lastDanmaku = lastItem
            super.after()
        }
    }
}
