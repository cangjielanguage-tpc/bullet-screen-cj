/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public abstract class BaseDanmaku <: Hashable & Comparable<BaseDanmaku> & ToString & Equatable<BaseDanmaku> {
    public static let DANMAKU_BR_CHAR: String = "/n"
    public static let TYPE_SCROLL_RL: Int64 = 1
    public static let TYPE_SCROLL_LR: Int64 = 6
    public static let TYPE_FIX_TOP: Int64 = 5
    public static let TYPE_FIX_BOTTOM: Int64 = 4
    public static let TYPE_SPECIAL: Int64 = 7
    public static let TYPE_MOVEABLE_XXX: Int64 = 0 // TODO: add more type

    public static let INVISIBLE: Int64 = 0
    public static let VISIBLE: Int64 = 1
    public static let FLAG_REQUEST_REMEASURE: Int64 = 0x1
    public static let FLAG_REQUEST_INVALIDATE: Int64 = 0x2

    var comparefunc: ?(BaseDanmaku, BaseDanmaku) -> Ordering = None

    /**
     * 显示时间(毫秒)
     */
    private var time: Int64 = 0

    /**
     * 偏移时间
     */
    public var timeOffset: Int64 = 0

    /**
     * 文本
     */
    public var text: String = ""

    /**
     * 多行文本: 如果有包含换行符需事先拆分到lines
     */
    public var lines: ?Array<String> = None

    /**
     * 保存一些数据的引用(库内部使用, 外部使用请用tag)
     */
    public var obj: Any = ()

    /**
     * 可保存一些自定义数据的引用(外部使用).
     * 除非主动set null,否则不会自动释放引用.
     * 确定你会主动set null, 否则不要使用这个字段引用大内存的对象实例.
     */
    private var tag: Any = ()

    /**
     * 文本颜色
     */
    public var textColor: UInt32 = 0

    /**
     * Z轴角度
     */
    public var rotationZ: Float64 = 0.0

    /**
     * Y轴角度
     */
    public var rotationY: Float64 = 0.0

    /**
     * 阴影/描边颜色
     */
    public var textShadowColor: UInt32 = 0

    /**
     * 下划线颜色,0表示无下划线
     */
    public var underlineColor: UInt32 = 0

    /**
     * 字体大小
     */
    public var textSize: Float64 = 65.0

    /**
     * 边框的颜色,0表示无边框
     */
    public var borderColor: UInt32 = 0

    /**
     * 内边距(像素)
     */
    public var padding: Float64 = 0.0

    /**
     * 弹幕优先级,0为低优先级,>0为高优先级不会被过滤器过滤
     */
    public var priority: UInt8 = 0

    /**
     * 占位宽度
     */
    public var paintWidth: Float64 = -1.0

    /**
     * 占位高度
     */
    public var paintHeight: Float64 = -1.0

    /**
     * 存活时间(毫秒)
     */
    public var duration: DanmakuDuration = DanmakuDuration(0)

    /**
     * 索引/编号
     */
    public var index: Int64 = 0

    /**
     * 是否可见
     */
    private var visibility: Int64 = 0

    /**
     * 重置位 visible
     */
    private var visibleResetFlag: Int64 = 0

    /**
     * 重置位 measure
     */
    public var measureResetFlag: Int64 = 0

    /**
     * 重置位 offset time
     */
    public var syncTimeOffsetResetFlag: Int64 = 0

    /**
     * 重置位 prepare
     */
    public var prepareResetFlag: Int64 = -1

    /**
     * 是否是直播弹幕
     */
    public var isLive: Bool = false

    /**
     * 临时, 是否在同线程创建缓存
     */
    public var forceBuildCacheInSameThread: Bool = true

    /**
     * 弹幕发布者id, 0表示游客
     */
    public var userId: Int64 = 0

    /**
     * 弹幕发布者id
     */
    public var userHash: String = ""

    /**
     * 是否游客
     */
    public var isGuest: Bool = true

    /**
     * 计时
     */
    protected var mTimer: ?DanmakuTimer = None

    /**
     * 透明度
     */
    protected var alpha: Int64 = ALPHA_MAX
    public var mFilterParam: Int64 = 0
    public var filterResetFlag: Int64 = -1
    public var flags: ?GlobalFlagValues = None
    public var requestFlags: Int64 = 0
    static var LAST_HASH: Int64 = 0
    protected var mHashCode: Int64
    public var isAnimation: Bool = false
    public var pixelMapList: ArrayList<PixelMap> = ArrayList<PixelMap>()

    public var firstShownFlag: Int64 = -1
    private var mTags: HashMap<Int64, Any> = HashMap<Int64, Any>()

    public init() {
        BaseDanmaku.LAST_HASH++
        mHashCode = BaseDanmaku.LAST_HASH
    }

    public func setPixelMapList(pixelMapList: ArrayList<PixelMap>): Unit {
        this.pixelMapList = pixelMapList
    }

    public func getPixelMapList(): ArrayList<PixelMap> {
        return this.pixelMapList
    }

    public func setIsAnimation(isAnimation: Bool): Unit {
        this.isAnimation = isAnimation
    }

    public func getIsAnimation(): Bool {
        return this.isAnimation
    }

    public func getDuration(): Int64 {
        return duration.value
    }

    public func setDuration(duration: DanmakuDuration): Unit {
        this.duration = duration
    }

    public func draw(displayer: IDisplayer): Int64 {
        return displayer.draw(this)
    }

    public func isMeasured(): Bool {
        return paintWidth > -1.0 && paintHeight > -1.0
            && measureResetFlag == flags().MEASURE_RESET_FLAG
    }

    public open func measure(displayer: IDisplayer, fromWorkerThread: Bool) {
        displayer.measure(this, fromWorkerThread)
        measureResetFlag = flags().MEASURE_RESET_FLAG
    }

    public func isPrepared(): Bool {
        return prepareResetFlag == flags().PREPARE_RESET_FLAG
    }

    public func prepare(displayer: IDisplayer, fromWorkerThread: Bool) {
        displayer.prepare(this, fromWorkerThread)
        prepareResetFlag = flags().PREPARE_RESET_FLAG
    }

    public open func isShown(): Bool {
        let a = visibility
        let b = BaseDanmaku.VISIBLE
        let c = visibility == BaseDanmaku.VISIBLE
        let d = visibleResetFlag
        let e = flags().VISIBLE_RESET_FLAG
        let f = visibleResetFlag == flags().VISIBLE_RESET_FLAG
        return visibility == BaseDanmaku.VISIBLE
            && visibleResetFlag == flags().VISIBLE_RESET_FLAG
    }

    public func isTimeOut(ctime!: ?Int64 = None): Bool {
        if (let Some(v) <- ctime) {
            return v - getActualTime() >= duration.value
        } else {
            return if (let Some(v) <- mTimer) {
                isTimeOut(ctime: v.currMillisecond)
            } else {
                true
            }
        }
    }

    public func isOutside(ctime!: ?Int64 = None): Bool {
        if (let Some(v) <- ctime) {
            let dtime: Int64 = v - getActualTime()
            return dtime <= 0 || dtime >= duration.value
        } else {
            return mTimer.isNone() || isOutside(ctime: mTimer.getOrThrow().currMillisecond)
        }
    }

    public func isLate(): Bool {
        return mTimer.isNone() || mTimer.getOrThrow().currMillisecond < getActualTime()
    }

    public func hasPassedFilter(): Bool {
        if (filterResetFlag != flags().FILTER_RESET_FLAG) {
            mFilterParam = 0
            return false
        }
        return true
    }

    public func isFiltered(): Bool {
        return filterResetFlag == flags().FILTER_RESET_FLAG && mFilterParam != 0
    }

    public func isFilteredBy(flag: Int64): Bool {
        return filterResetFlag == flags().FILTER_RESET_FLAG && (mFilterParam & flag) == flag
    }

    public func setVisibility(b: Bool) {
        if (b) {
            visibleResetFlag = flags().VISIBLE_RESET_FLAG
            visibility = BaseDanmaku.VISIBLE
        } else {
            visibility = BaseDanmaku.INVISIBLE
        }
    }

    public open func layout(displayer: IDisplayer, x: Float64, y: Float64): Unit

    public open func getRectAtTime(displayer: IDisplayer, currTime: Int64): ?Array<Float64>

    public open func getLeft(): Float64

    public open func getTop(): Float64

    public open func getRight(): Float64

    public open func getBottom(): Float64

    /**
     * return the type of Danmaku
     *
     * @return TYPE_SCROLL_RL = 0 TYPE_SCROLL_RL = 1 TYPE_SCROLL_LR = 2
     * TYPE_FIX_TOP = 3 TYPE_FIX_BOTTOM = 4
     */
    public open func getType(): Int64

    public func getTimer(): ?DanmakuTimer {
        return mTimer
    }

    public func setTimer(timer: DanmakuTimer): Unit {
        mTimer = timer
    }

    public func getAlpha(): Int64 {
        return alpha
    }

    public func setTag(tag: Any, key!: ?Int64 = None) {
        if (let Some(v) <- key) {
            mTags.put(v, tag)
        } else {
            this.tag = tag
        }
    }

    public func getTag(key: Int64): ?Any {
        if (mTags.isEmpty()) {
            return None
        }
        return mTags.get(key)
    }

    public func setTimeOffset(timeOffset: Int64): Unit {
        this.timeOffset = timeOffset
        syncTimeOffsetResetFlag = flags().SYNC_TIME_OFFSET_RESET_FLAG
    }

    public func setTime(time: Int64): Unit {
        this.time = time
        timeOffset = 0
    }

    public func getTime(): Int64 {
        return time
    }

    public func getActualTime(): Int64 {
        if (flags.isNone() || flags().SYNC_TIME_OFFSET_RESET_FLAG != syncTimeOffsetResetFlag) {
            timeOffset = 0
            return time
        }
        return time + timeOffset
    }

    public func isOffset(): Bool {
        if (flags.isNone() || flags().SYNC_TIME_OFFSET_RESET_FLAG != syncTimeOffsetResetFlag) {
            timeOffset = 0
            return false
        }
        return timeOffset != 0
    }

    public operator func ==(other: BaseDanmaku): Bool {
        return refEq(this, other)
    }

    public operator func !=(other: BaseDanmaku): Bool {
        return !(this == other)
    }

    public operator func >(other: BaseDanmaku): Bool {
        return compare(other) == Ordering.GT
    }

    public operator func <(other: BaseDanmaku): Bool {
        return compare(other) == Ordering.LT
    }

    public operator func >=(other: BaseDanmaku): Bool {
        return compare(other) == Ordering.GT || compare(other) == Ordering.EQ
    }

    public operator func <=(other: BaseDanmaku): Bool {
        return compare(other) == Ordering.LT || compare(other) == Ordering.EQ
    }

    func setCompareMethod(other: (BaseDanmaku, BaseDanmaku) -> Ordering): Unit {
        this.comparefunc = other
    }
    public open func compare(other: BaseDanmaku): Ordering {
        if (let Some(v) <- comparefunc) {
            return v(this, other)
        }
        if (DanmakuUtils.isDuplicate(this, other)) {
            return Ordering.EQ
        }
        return DanmakuUtils.compare(this, other)
    }

    public func hashCode(): Int64 {
        return mHashCode
    }

    public func toString(): String {
        return "BaseDanmaku{time=${time}, duration=${duration.value}, visibility=${visibility}, text=${text}"
    }
}
