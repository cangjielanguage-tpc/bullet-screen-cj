/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class DanmakusRetainer {
    private var rldrInstance: ?IDanmakusRetainer = Option<IDanmakusRetainer>.None
    private var lrdrInstance: ?IDanmakusRetainer = Option<IDanmakusRetainer>.None
    private var ftdrInstance: ?IDanmakusRetainer = Option<IDanmakusRetainer>.None
    private var fbdrInstance: ?IDanmakusRetainer = Option<IDanmakusRetainer>.None

    public init(alignBottom: Bool) {
        setAlignBottom(alignBottom)
    }

    public func setAlignBottom(alignBottom: Bool): Unit {
        //r2l, 使用AlignBottom或AlignTop
        rldrInstance = if (alignBottom) {
            AlignBottomRetainer()
        } else {
            AlignTopRetainer()
        }
        //l2r, 使用AlignBottom或AlignTop
        lrdrInstance = if (alignBottom) {
            AlignBottomRetainer()
        } else {
            AlignTopRetainer()
        }
        if (ftdrInstance.isNone()) {
            ftdrInstance = FTDanmakusRetainer() //fix top
        }
        if (fbdrInstance.isNone()) {
            fbdrInstance = AlignBottomRetainer() //fix bottom 使用 AlignBottomRetainer逻辑
        }
    }

    public func fix(danmaku: BaseDanmaku, disp: IDisplayer, verifier: ?Verifier): Unit {
        let danmakuType: Int64 = danmaku.getType()
        if (danmakuType == BaseDanmaku.TYPE_SCROLL_RL) {
            rldrInstance().fix(danmaku, disp, verifier)
        } else if (danmakuType == BaseDanmaku.TYPE_SCROLL_LR) {
            lrdrInstance().fix(danmaku, disp, verifier)
        } else if (danmakuType == BaseDanmaku.TYPE_FIX_TOP) {
            ftdrInstance().fix(danmaku, disp, verifier)
        } else if (danmakuType == BaseDanmaku.TYPE_FIX_BOTTOM) {
            fbdrInstance().fix(danmaku, disp, verifier)
        } else if (danmakuType == BaseDanmaku.TYPE_SPECIAL) {
            danmaku.layout(disp, 0.0, 0.0)
        }
    }

    public func clear(): Unit {
        if (let Some(v) <- rldrInstance) {
            v.clear()
        }
        if (let Some(v) <- lrdrInstance) {
            v.clear()
        }
        if (let Some(v) <- ftdrInstance) {
            v.clear()
        }
        if (let Some(v) <- fbdrInstance) {
            v.clear()
        }
    }

    public func release(): Unit {
        clear()
    }
}

public interface Verifier {
    func skipLayout(danmaku: BaseDanmaku, fixedTop: Float64, lines: Int64, willHit: Bool): Bool
}

public interface IDanmakusRetainer {
    func fix(drawItem: BaseDanmaku, disp: IDisplayer, verifier: ?Verifier): Unit

    func clear(): Unit
}

public class RetainerState {
    public var lines: Int64 = 0
    public var insertItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var firstItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var lastItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var minRightRow: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var removeItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var overwriteInsert: Bool = false
    public var shown: Bool = false
    public var willHit: Bool = false
}


class RetainerConsumerTop <: Consumer<BaseDanmaku, RetainerState> {
    public var disp: IDisplayer = OhcjDisplayer()
    var lines: Int64 = 0
    public var insertItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var firstItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var lastItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var minRightRow: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var drawItem: BaseDanmaku = Danmaku("")
    var overwriteInsert: Bool = false
    var shown: Bool = false
    var willHit: Bool = false
    var outer: IAlignTopRetainer

    init(outer: IAlignTopRetainer) {
        this.outer = outer
    }

    public override func before(): Unit {
        lines = 0
        insertItem = None
        firstItem = None
        lastItem = None
        minRightRow = None
        overwriteInsert = false
        shown = false
        willHit = false
    }

    public override func accept(item: BaseDanmaku): Int64 {
        if (outer.mCancelFixingFlag) {
            return ACTION_BREAK
        }
        lines++
        if (item == drawItem) {
            insertItem = item
            lastItem = None
            shown = true
            willHit = false
            return ACTION_BREAK
        }

        if (firstItem.isNone()) {
            firstItem = item
        }

        if (drawItem.paintHeight + item.getTop() > disp.getHeight()) {
            overwriteInsert = true
            return ACTION_BREAK
        }

        if (minRightRow.isNone()) {
            minRightRow = item
        } else {
            if (minRightRow().getRight() >= item.getRight()) {
                minRightRow = item
            }
        }

        // 检查碰撞
        if (let Some(v) <- drawItem.getTimer()) {
            willHit = DanmakuUtils.willHitInDuration(disp, item, drawItem, drawItem.getDuration(), v.currMillisecond)
            if (!willHit) {
                insertItem = item
                return ACTION_BREAK
            }
        }
        lastItem = item
        return ACTION_CONTINUE
    }

    public func result(): ?RetainerState {
        let retainerState: RetainerState = RetainerState()
        retainerState.lines = lines
        retainerState.firstItem = firstItem
        retainerState.insertItem = insertItem
        retainerState.lastItem = lastItem
        retainerState.minRightRow = minRightRow
        retainerState.overwriteInsert = overwriteInsert
        retainerState.shown = shown
        retainerState.willHit = willHit
        return retainerState
    }
}

abstract class IAlignTopRetainer <: IDanmakusRetainer {
    protected var mVisibleDanmakus: Danmakus = Danmakus(ST_BY_YPOS)
    protected var mCancelFixingFlag: Bool = false
    protected var mConsumerTop: RetainerConsumerTop

    public init(that: IAlignTopRetainer) {
        mConsumerTop = RetainerConsumerTop(that)
    }

    public open override func fix(drawItem: BaseDanmaku, disp: IDisplayer, verifier: ?Verifier): Unit {
        if (drawItem.isOutside()) {
            return
        }
        var topPos: Float64 = Float64(disp.getAllMarginTop())
        var lines: Int64 = 0
        var shown: Bool = drawItem.isShown()
        var willHit: Bool = !shown && !mVisibleDanmakus.isEmpty()
        var isOutOfVertialEdge: Bool = false
        var removeItem: ?BaseDanmaku = Option<BaseDanmaku>.None
        let margin: Int64 = disp.getMargin()
        if (!shown) {
            mCancelFixingFlag = false
            // 确定弹幕位置
            var insertItem: ?BaseDanmaku = Option<BaseDanmaku>.None
            var firstItem: ?BaseDanmaku = Option<BaseDanmaku>.None
            var lastItem: ?BaseDanmaku = Option<BaseDanmaku>.None
            var minRightRow: ?BaseDanmaku = Option<BaseDanmaku>.None
            var overwriteInsert: Bool = false
            mConsumerTop.disp = disp
            mConsumerTop.drawItem = drawItem
            mVisibleDanmakus.forEachSync(mConsumerTop)
            let retainerState: ?RetainerState = mConsumerTop.result()
            if (let Some(v) <- retainerState) {
                lines = v.lines
                insertItem = v.insertItem
                firstItem = v.firstItem
                lastItem = v.lastItem
                minRightRow = v.minRightRow
                overwriteInsert = v.overwriteInsert
                shown = v.shown
                willHit = v.willHit
            }
            var checkEdge: Bool = true
            if (let Some(v) <- insertItem) {
                if (let Some(j) <- lastItem) {
                    topPos = j.getBottom() + Float64(margin)
                } else {
                    topPos = v.getTop()
                }
                if (v != drawItem) {
                    removeItem = v
                    shown = false
                }
            } else if (overwriteInsert) {
                if (let Some(v) <- minRightRow) {
                    topPos = v.getTop()
                    checkEdge = false
                    shown = false
                }
            } else if (let Some(v) <- lastItem) {
                topPos = v.getBottom() + Float64(margin)
                willHit = false
            } else if (let Some(v) <- firstItem) {
                topPos = v.getTop()
                removeItem = v
                shown = false
            } else {
                topPos = Float64(disp.getAllMarginTop())
            }
            if (checkEdge) {
                isOutOfVertialEdge = isOutVerticalEdge(overwriteInsert, drawItem, disp, topPos, firstItem, lastItem)
            }
            if (isOutOfVertialEdge) {
                topPos = Float64(disp.getAllMarginTop())
                willHit = true
                lines = 1
            } else if (removeItem.isSome()) {
                lines--
            }
            if (topPos == Float64(disp.getAllMarginTop())) {
                shown = false
            }
        }
        if (verifier.isSome() && verifier().skipLayout(drawItem, topPos, lines, willHit)) {
            return
        }
        if (isOutOfVertialEdge) {
            clear()
        }
        drawItem.layout(disp, drawItem.getLeft(), Float64(topPos))
        if (!shown) {
            mVisibleDanmakus.removeItem(removeItem)
            mVisibleDanmakus.addItem(drawItem)
        }
    }

    protected open func isOutVerticalEdge(overwriteInsert: Bool, drawItem: BaseDanmaku, disp: IDisplayer,
        topPos: Float64, firstItem: ?BaseDanmaku, lastItem: ?BaseDanmaku): Bool {
        if (topPos < Float64(disp.getAllMarginTop()) || (firstItem.isSome() && firstItem().getTop() > 0.0) ||
            topPos + drawItem.paintHeight > disp.getHeight()) {
            return true
        }
        return false
    }

    public open override func clear(): Unit {
        mCancelFixingFlag = true
        mVisibleDanmakus.clear()
    }
}

class AlignTopRetainer <: IAlignTopRetainer {
    public init() {
        super(this)
    }
}

abstract class IFTDanmakusRetainer <: IAlignTopRetainer {
    public init(that: IAlignTopRetainer) {
        super(that)
    }
    protected open override func isOutVerticalEdge(overwriteInsert: Bool, drawItem: BaseDanmaku, disp: IDisplayer,
        topPos: Float64, firstItem: ?BaseDanmaku, lastItem: ?BaseDanmaku): Bool {
        if (topPos + drawItem.paintHeight > disp.getHeight()) {
            return true
        }
        return false
    }
}

class FTDanmakusRetainer <: IFTDanmakusRetainer{
    public init() {
        super(this)
    }
}


class RetainerConsumerBottom <: Consumer<BaseDanmaku, RetainerState> {
    public var disp: IDisplayer = OhcjDisplayer()
    var lines: Int64 = 0
    public var removeItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var firstItem: ?BaseDanmaku = Option<BaseDanmaku>.None
    public var drawItem: BaseDanmaku = Danmaku("")
    var willHit: Bool = false
    var topPos: Float64 = 0.0
    var outer: AlignBottomRetainer
    public init(outer: AlignBottomRetainer) {
        this.outer = outer
    }

    public override func before(): Unit {
        lines = 0
        removeItem = None
        firstItem = None
        willHit = false
    }

    public override func accept(item: BaseDanmaku): Int64 {
        if (outer.mCancelFixingFlag) {
            return ACTION_BREAK
        }
        lines++
        if (item == drawItem) {
            removeItem = None
            willHit = false
            return ACTION_BREAK
        }

        if (firstItem.isNone()) {
            firstItem = item
            if (firstItem().getBottom() != disp.getHeight()) {
                return ACTION_BREAK
            }
        }

        if (topPos < Float64(disp.getAllMarginTop())) {
            removeItem = None
            return ACTION_BREAK
        }

        // 检查碰撞
        if (let Some(v) <- drawItem.getTimer()) {
            willHit = DanmakuUtils.willHitInDuration(disp, item, drawItem, drawItem.getDuration(), v.currMillisecond)
            if (!willHit) {
                removeItem = item
                return ACTION_BREAK
            }
        }
        topPos = item.getTop() - Float64(disp.getMargin()) - drawItem.paintHeight
        return ACTION_CONTINUE
    }

    public func result(): ?RetainerState {
        let retainerState: RetainerState = RetainerState()
        retainerState.lines = lines
        retainerState.firstItem = firstItem
        retainerState.removeItem = removeItem
        retainerState.willHit = willHit
        return retainerState
    }
}

class AlignBottomRetainer <: IFTDanmakusRetainer {
    protected var mConsumerBottom: RetainerConsumerBottom = unsafe {zeroValue<RetainerConsumerBottom>()}
    public init() {
        super(this)
        mVisibleDanmakus = Danmakus(ST_BY_YPOS_DESC)
        this.mConsumerBottom = RetainerConsumerBottom(this)
    }

    public override func fix(drawItem: BaseDanmaku, disp: IDisplayer, verifier: ?Verifier): Unit {
        if (drawItem.isOutside()) {
            return
        }
        var shown: Bool = drawItem.isShown()
        var topPos: Float64 = if (shown) {
            drawItem.getTop()
        } else {
            -1.0
        }
        var lines: Int64 = 0
        var willHit: Bool = !shown && !mVisibleDanmakus.isEmpty()
        var isOutOfVerticalEdge: Bool = false
        if (topPos < Float64(disp.getAllMarginTop())) {
            topPos = disp.getHeight() - drawItem.paintHeight
        }
        var removeItem: ?BaseDanmaku = Option<BaseDanmaku>.None
        var firstItem: ?BaseDanmaku = Option<BaseDanmaku>.None
        if (!shown) {
            mCancelFixingFlag = false
            mConsumerBottom.topPos = topPos
            mConsumerBottom.disp = disp
            mConsumerBottom.drawItem = drawItem
            mVisibleDanmakus.forEachSync(mConsumerBottom)
            let retainerState: ?RetainerState = mConsumerBottom.result()
            topPos = mConsumerBottom.topPos
            if (let Some(v) <- retainerState) {
                lines = v.lines
                firstItem = v.firstItem
                removeItem = v.removeItem
                shown = v.shown
                willHit = v.willHit
            }
            isOutOfVerticalEdge = isOutVerticalEdge(false, drawItem, disp, topPos, firstItem, Option<BaseDanmaku>.None)
            if (isOutOfVerticalEdge) {
                topPos = disp.getHeight() - drawItem.paintHeight
                willHit = true
                lines = 1
            } else {
                if (topPos >= Float64(disp.getAllMarginTop())) {
                    willHit = false
                }
                if (removeItem.isSome()) {
                    lines--
                }
            }
        }
        if (verifier.isSome() && verifier().skipLayout(drawItem, topPos, lines, willHit)) {
            return
        }
        if (isOutOfVerticalEdge) {
            clear()
        }
        drawItem.layout(disp, drawItem.getLeft(), topPos)
        if (!shown) {
            mVisibleDanmakus.removeItem(removeItem)
            mVisibleDanmakus.addItem(drawItem)
        }
    }

    protected override func isOutVerticalEdge(overwriteInsert: Bool, drawItem: BaseDanmaku, disp: IDisplayer,
        topPos: Float64, firstItem: ?BaseDanmaku, lastItem: ?BaseDanmaku): Bool {
        if (topPos < Float64(disp.getAllMarginTop()) || (firstItem.isSome() && firstItem().getBottom() !=
            disp.getHeight())) {
            return true
        }
        return false
    }

    public override func clear(): Unit {
        mCancelFixingFlag = true
        mVisibleDanmakus.clear()
    }
}

