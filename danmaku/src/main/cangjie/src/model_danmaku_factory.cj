/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public class DanmakuFactory {
    public static let OLD_BILI_PLAYER_WIDTH: Int64 = 539
    public static let BILI_PLAYER_WIDTH: Int64 = 682
    public static let OLD_BILI_PLAYER_HEIGHT: Int64 = 385
    public static let BILI_PLAYER_HEIGHT: Int64 = 438
    public static let COMMON_DANMAKU_DURATION: Int64 = 3800 // 原始分辨率下弹幕存活时间
    public static let DANMAKU_MEDIUM_TEXTSIZE: Int64 = 25
    public static let MIN_DANMAKU_DURATION: Int64 = 4000
    public static let MAX_DANMAKU_DURATION_HIGH_DENSITY: Int64 = 9000
    public var CURRENT_DISP_WIDTH: Float64 = 0.0
    public var CURRENT_DISP_HEIGHT: Float64 = 0.0
    private var mScaleFactor: ?ScaleFactor = None
    private var CURRENT_DISP_SIZE_FACTOR: Float64 = 1.0
    public var REAL_DANMAKU_DURATION: Int64 = DanmakuFactory.COMMON_DANMAKU_DURATION
    public var MAX_DANMAKU_DURATION: Int64 = DanmakuFactory.MIN_DANMAKU_DURATION
    public var MAX_Duration_Scroll_Danmaku: ?DanmakuDuration = None
    public var MAX_Duration_Fix_Danmaku: ?DanmakuDuration = None
    public var MAX_Duration_Special_Danmaku: ?DanmakuDuration = None
    public var sLastDisp: IDisplayer = OhcjDisplayer()
    private var sLastConfig: ?DanmakuContext = None

    public static func create(): DanmakuFactory {
        return DanmakuFactory()
    }

    protected init() {
    }

    public func resetDurationsData(): Unit {
        sLastDisp = OhcjDisplayer()
        CURRENT_DISP_WIDTH = 0.0
        CURRENT_DISP_HEIGHT = 0.0
        MAX_Duration_Scroll_Danmaku = None
        MAX_Duration_Fix_Danmaku = None
        MAX_Duration_Special_Danmaku = None
        MAX_DANMAKU_DURATION = DanmakuFactory.MIN_DANMAKU_DURATION
    }

    public func notifyDispSizeChanged(context: DanmakuContext): Unit {
        sLastConfig = context
        sLastDisp = context.getDisplayer()
        createDanmakuByContext(BaseDanmaku.TYPE_SCROLL_RL, context)
    }

    /**
     * 创建弹幕数据请尽量使用此方法
     *
     * @param t               弹幕类型
     * @param viewportWidth      danmakuview宽度,会影响滚动弹幕的存活时间(duration)
     * @param viewportHeight     danmakuview高度
     * @param viewportSizeFactor 会影响滚动弹幕的速度/存活时间(duration)
     * @return
     */
    public func createDanmaku(t: Int64): ?BaseDanmaku {
        return createDanmakuByContext(t, sLastConfig)
    }

    public func createDanmakuByContext(t: Int64, context: ?DanmakuContext): ?BaseDanmaku {
        if (context.isNone()) {
            return None
        }
        sLastConfig = context
        let realContext: DanmakuContext = context()
        sLastDisp = realContext.getDisplayer()
        return createDanmakuByAll(t, sLastDisp.getWidth(), sLastDisp.getHeight(), CURRENT_DISP_SIZE_FACTOR,
            realContext.scrollSpeedFactor)
    }

    public func createDanmakuByDisplayer(t: Int64, disp: ?IDisplayer, viewportScale: Float64, scrollSpeedFactor: Float64): ?BaseDanmaku {
        if (disp.isNone()) {
            return None
        }
        let realDisp = disp()
        sLastDisp = realDisp
        return createDanmakuByAll(t, realDisp.getWidth(), realDisp.getHeight(), viewportScale, scrollSpeedFactor)
    }

    public func createDanmakuByAll(t: Int64, viewportWidth: Float64, viewportHeight: Float64, viewportScale: Float64,
        scrollSpeedFactor: Float64): ?BaseDanmaku {
        let oldDispWidth: Float64 = CURRENT_DISP_WIDTH
        let oldDispHeight: Float64 = CURRENT_DISP_HEIGHT
        let sizeChanged: Bool = updateViewportState(viewportWidth, viewportHeight, viewportScale)
        if (MAX_Duration_Scroll_Danmaku.isNone()) {
            MAX_Duration_Scroll_Danmaku = DanmakuDuration(REAL_DANMAKU_DURATION)
            MAX_Duration_Scroll_Danmaku().setFactor(scrollSpeedFactor)
        } else if (sizeChanged) {
            MAX_Duration_Scroll_Danmaku().setValue(REAL_DANMAKU_DURATION)
        }
        if (MAX_Duration_Fix_Danmaku.isNone()) {
            MAX_Duration_Fix_Danmaku = DanmakuDuration(DanmakuFactory.COMMON_DANMAKU_DURATION)
        }
        var scaleX: Float64 = 1.0
        var scaleY: Float64 = 1.0
        if (sizeChanged && viewportWidth > 0.0) {
            updateMaxDanmakuDuration()
            if (oldDispWidth > 0.0 && oldDispHeight > 0.0) {
                scaleX = viewportWidth / oldDispWidth
                scaleY = viewportHeight / oldDispHeight
            }
            updateScaleFactor(viewportWidth, viewportHeight, scaleX, scaleY)
            if (viewportHeight > 0.0) {
                updateSpecialDanmakusDate(viewportWidth, viewportHeight, scaleX, scaleY)
            }
        }
        var instance: ?BaseDanmaku = None
        match (t) {
            case 1 => // 从右往左滚动
                instance = R2LDanmaku(MAX_Duration_Scroll_Danmaku.getOrThrow())
            case 4 => // 底端固定
                instance = FBDanmaku(MAX_Duration_Fix_Danmaku.getOrThrow())
            case 5 => // 顶端固定
                instance = FTDanmaku(MAX_Duration_Fix_Danmaku.getOrThrow())
            case 6 => // 从左往右滚动
                instance = L2RDanmaku(MAX_Duration_Scroll_Danmaku.getOrThrow())
            case 7 => // 特殊弹幕
                instance = SpecialDanmaku()
                updateScaleFactor(viewportWidth, viewportHeight, scaleX, scaleY)
                (instance() as SpecialDanmaku)().setScaleFactor(mScaleFactor())
            case _ => ()
        }
        return instance
    }

    private func updateScaleFactor(width: Float64, height: Float64, scaleX: Float64, scaleY: Float64): Unit {
        if (let Some(v) <- mScaleFactor) {
            v.update(width, height, scaleX, scaleY)
        } else {
            mScaleFactor = ScaleFactor(width, height, scaleX, scaleY)
        }
    }

    public func updateViewportState(viewportWidth: Float64, viewportHeight: Float64, viewportSizeFactor: Float64): Bool {
        var sizeChanged: Bool = false
        if (CURRENT_DISP_WIDTH != viewportWidth || CURRENT_DISP_HEIGHT != viewportHeight || CURRENT_DISP_SIZE_FACTOR !=
            viewportSizeFactor) {
            sizeChanged = true
            REAL_DANMAKU_DURATION = (DanmakuFactory.COMMON_DANMAKU_DURATION * (Int64(viewportSizeFactor
                * viewportWidth) / DanmakuFactory.BILI_PLAYER_WIDTH))
            REAL_DANMAKU_DURATION = min(DanmakuFactory.MAX_DANMAKU_DURATION_HIGH_DENSITY, REAL_DANMAKU_DURATION)
            REAL_DANMAKU_DURATION = max(DanmakuFactory.MIN_DANMAKU_DURATION, REAL_DANMAKU_DURATION)
            CURRENT_DISP_WIDTH = viewportWidth
            CURRENT_DISP_HEIGHT = viewportHeight
            CURRENT_DISP_SIZE_FACTOR = viewportSizeFactor
        }
        return sizeChanged
    }

    private func updateSpecialDanmakusDate(width: Float64, height: Float64, scaleX: Float64, scaleY: Float64): Unit {
        if (let Some(v) <- mScaleFactor) {
            v.update(width, height, scaleX, scaleY)
        }
    }

    public func updateMaxDanmakuDuration(): Unit {
        let maxScrollDuration: Int64 = if (let Some(v) <- MAX_Duration_Scroll_Danmaku) {
            v.value
        } else {
            0
        }
        let maxFixDuration: Int64 = if (let Some(v) <- MAX_Duration_Fix_Danmaku) {
            v.value
        } else {
            0
        }
        let maxSpecialDuration: Int64 = if (let Some(v) <- MAX_Duration_Special_Danmaku) {
            v.value
        } else {
            0
        }
        MAX_DANMAKU_DURATION = max(maxScrollDuration, maxFixDuration)
        MAX_DANMAKU_DURATION = max(MAX_DANMAKU_DURATION, maxSpecialDuration)
        MAX_DANMAKU_DURATION = max(DanmakuFactory.COMMON_DANMAKU_DURATION, MAX_DANMAKU_DURATION)
        MAX_DANMAKU_DURATION = max(REAL_DANMAKU_DURATION, MAX_DANMAKU_DURATION)
    }

    public func updateDurationFactor(f: Float64): Unit {
        if (MAX_Duration_Scroll_Danmaku.isNone() || MAX_Duration_Fix_Danmaku.isNone()) {
            return
        }
        MAX_Duration_Scroll_Danmaku().setFactor(f)
        updateMaxDanmakuDuration()
    }

    /**
     * Initial translation data of the special danmaku
     *
     * @param item
     * @param beginX
     * @param beginX
     * @param beginY
     * @param endX
     * @param endY
     * @param translationDuration
     * @param translationStartDelay
     */
    public func fillTranslationData(item: BaseDanmaku, beginX: Float64, beginY: Float64, endX: Float64, endY: Float64,
        translationDuration: Int64, translationStartDelay: Int64, scaleX: Float64, scaleY: Float64): Unit {
        if (item.getType() != BaseDanmaku.TYPE_SPECIAL) {
            return
        }
        (item as SpecialDanmaku)().setTranslationData(beginX * scaleX, beginY * scaleY, endX * scaleX, endY * scaleY,
            translationDuration, translationStartDelay)
        updateSpecicalDanmakuDuration(item)
    }

    public static func fillLinePathData(item: BaseDanmaku, points: Array<Array<Float64>>, scaleX: Float64,
        scaleY: Float64): Unit {
        if (item.getType() != BaseDanmaku.TYPE_SPECIAL || points.size == 0 || points[0].size != 2) {
            return
        }
        for (i in 0..points.size) {
            points[i][0] *= scaleX
            points[i][1] *= scaleY
        }
        (item as SpecialDanmaku)().setLinePathData(points)
    }

    /**
     * Initial alpha data of the special danmaku
     *
     * @param item
     * @param beginAlpha
     * @param endAlpha
     * @param alphaDuraion
     */
    public func fillAlphaData(item: BaseDanmaku, beginAlpha: Int64, endAlpha: Int64, alphaDuraion: Int64): Unit {
        if (item.getType() != BaseDanmaku.TYPE_SPECIAL) {
            return
        }
        (item as SpecialDanmaku)().setAlphaData(beginAlpha, endAlpha, alphaDuraion)
        updateSpecicalDanmakuDuration(item)
    }

    private func updateSpecicalDanmakuDuration(item: BaseDanmaku): Unit {
        if (MAX_Duration_Special_Danmaku.isNone() || (item.duration.value > MAX_Duration_Special_Danmaku().value)) {
            MAX_Duration_Special_Danmaku = item.duration
            updateMaxDanmakuDuration()
        }
    }
}
