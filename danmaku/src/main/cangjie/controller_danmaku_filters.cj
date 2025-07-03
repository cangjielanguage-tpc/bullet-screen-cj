/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public interface IDanmakuFilter {
    /*
     * 是否过滤
     */
    func filter(danmaku: ?BaseDanmaku, index: Int64, totalsizeInScreen: Int64, timer: DanmakuTimer,
        fromCachingTask: Bool, config: DanmakuContext): Bool

    func reset(): Unit

    func clear(): Unit

    func hashCode(): Int64
}

public abstract class BaseDanmakuFilter<T> <: IDanmakuFilter {

    public func setData(data: ?T): Unit

    public open override func clear(): Unit {}

    @OverflowWrapping
    public open override func hashCode(): Int64 {
        return Random().nextInt64() * 31
    }
}

/**
 * 根据弹幕类型过滤
 *
 */
public class TypeDanmakuFilter <: BaseDanmakuFilter<ArrayList<Int64>> {
    let mFilterTypes: ArrayList<Int64> = ArrayList<Int64>()
    let mtx = ReentrantMutex()

    public func enableType(t: Int64): Unit {
        synchronized(mtx) {
            if (!mFilterTypes.contains(t)) {
                mFilterTypes.add(t)
            }
        }
    }

    public func disableType(t: Int64): Unit {
        synchronized(mtx) {
            if (mFilterTypes.contains(t)) {
                mFilterTypes.remove(at: t)
            }
        }
    }

    public override func filter(danmaku: ?BaseDanmaku, _: Int64, _: Int64,
        _: DanmakuTimer, _: Bool, _: DanmakuContext): Bool {
        let filtered: Bool = danmaku.isSome() && mFilterTypes.contains(danmaku().getType())
        if (filtered) {
            danmaku().mFilterParam |= DanmakuFilters.FILTER_TYPE_TYPE
        }
        return filtered
    }

    public override func setData(data: ?ArrayList<Int64>): Unit {
        reset()
        if(let Some(v) <- data) {
            if (!v.isEmpty()) {
                for (value in v) {
                    enableType(value)
                }
            }
        }
    }

    public override func reset(): Unit {
        synchronized(mtx) {
            mFilterTypes.clear()
        }
    }
}

/**
 * 根据同屏数量过滤弹幕
 *
 */
public class QuantityDanmakuFilter <: BaseDanmakuFilter<Int64> {
    protected var mMaximumSize: Int64 = -1
    protected var mLastSkipped: ?BaseDanmaku = None
    private var mFilterFactor: Int64 = 1
    let mtx = ReentrantMutex()

    private func needFilter(danmaku: BaseDanmaku, orderInScreen: Int64, _: Int64, _: DanmakuTimer,
        _: Bool, context: DanmakuContext): Bool {
        if (mMaximumSize <= 0 || danmaku.getType() != BaseDanmaku.TYPE_SCROLL_RL) {
            return false
        }

        if (mLastSkipped.isNone()) {
            mLastSkipped = danmaku
            return false
        }

        if ( mLastSkipped().isTimeOut()) {
            mLastSkipped = danmaku
            return false
        }

        let gapTime: Int64 = danmaku.getActualTime() - mLastSkipped().getActualTime()
        let maximumScrollDuration: ?DanmakuDuration = context.mDanmakuFactory.MAX_Duration_Scroll_Danmaku
        if (gapTime >= 0 && maximumScrollDuration.isSome() && gapTime < (maximumScrollDuration().value * mFilterFactor)) {
            return true
        }

        if (orderInScreen > mMaximumSize) {
            return true
        }
        mLastSkipped = danmaku
        return false
    }

    public override func filter(danmaku: ?BaseDanmaku, orderInScreen: Int64, totalsizeInScreen: Int64,
        timer: DanmakuTimer, fromCachingTask: Bool, config: DanmakuContext): Bool {
        synchronized(mtx) {
            if (let Some(v) <- danmaku) {
                let filtered: Bool = needFilter(v, orderInScreen, totalsizeInScreen, timer, fromCachingTask, config)
                if (filtered) {
                    v.mFilterParam |= DanmakuFilters.FILYER_TYPE_QUANTITY
                }
                return filtered
            }
            return false
        }
    }

    public override func setData(data: ?Int64): Unit {
        reset()
        if (let Some(v) <- data) {
            if (v != mMaximumSize) {
                mMaximumSize = v + v / 5
                mFilterFactor = 1 / mMaximumSize
            }
        }
    }

    public override func reset(): Unit {
        synchronized(mtx) {
            mLastSkipped = None
        }
    }

    public override func clear(): Unit {
        reset()
    }
}

/**
 * 根据绘制耗时过滤弹幕
 *
 */
public class ElapsedTimeFilter <: BaseDanmakuFilter<Any> {
    let mMaxTime: Int64 = 20 // 绘制超过20ms就跳过 ，默认保持接近50fps
    let mtx = ReentrantMutex()

    private func needFilter(danmaku: BaseDanmaku, _: Int64, _: Int64, timer: DanmakuTimer,
        _: Bool): Bool {
        if (!danmaku.isOutside()) {
            return false
        }
        let elapsedTime: Int64 = SystemClock.uptimeMillis() - timer.currMillisecond
        if (elapsedTime >= mMaxTime) {
            return true
        }
        return false
    }

    public override func filter(danmaku: ?BaseDanmaku, orderInScreen: Int64, totalsizeInScreen: Int64,
        timer: DanmakuTimer, fromCachingTask: Bool, _: DanmakuContext): Bool {
        if (let Some(v) <- danmaku) {
            let filtered: Bool = needFilter(v, orderInScreen, totalsizeInScreen, timer, fromCachingTask)
            if (filtered) {
                v.mFilterParam |= DanmakuFilters.FILTER_TYPE_ELAPSED_TIME
            }
            return filtered
        }
        return false
    }

    public override func setData(_: ?Any): Unit {
        reset()
    }

    public override func reset(): Unit {
        synchronized(mtx) {}
    }

    public override func clear(): Unit {
        reset()
    }
}

/**
 * 根据文本颜色白名单过滤
 *
 */
public class TextColorFilter <: BaseDanmakuFilter<ArrayList<UInt32>> {
    public let mWhiteList: ArrayList<UInt32> = ArrayList<UInt32>()

    private func addToWhiteList(color: UInt32): Unit {
        if (!mWhiteList.contains(color)) {
            mWhiteList.add(color)
        }
    }

    public override func filter(danmaku: ?BaseDanmaku, _: Int64, _: Int64, _: DanmakuTimer,
        _: Bool, _: DanmakuContext): Bool {
        let filtered: Bool = danmaku.isSome() && !mWhiteList.contains(danmaku().textColor)
        if (filtered) {
            danmaku().mFilterParam |= DanmakuFilters.FILTER_TYPE_TEXTCOLOR
        }
        return filtered
    }

    public override func setData(data: ?ArrayList<UInt32>): Unit {
        reset()
        if(let Some(v) <- data) {
            if (!v.isEmpty()) {
                for (value in v) {
                    addToWhiteList(value)
                }
            }
        }
    }

    public override func reset(): Unit {
        mWhiteList.clear()
    }
}

/**
 * 根据用户标识黑名单过滤
 *
 */
public abstract class UserFilter<T> <: BaseDanmakuFilter<ArrayList<T>> where T <: Equatable<T> {
    public let mBlackList: ArrayList<T> = ArrayList<T>()

    private func addToBlackList(id: T): Unit {
        if (!mBlackList.contains(id)) {
            mBlackList.add(id)
        }
    }

    public open override func filter(danmaku: ?BaseDanmaku, index: Int64, totalsizeInScreen: Int64, timer: DanmakuTimer,
        fromCachingTask: Bool, config: DanmakuContext): Bool

    public override func setData(data: ?ArrayList<T>): Unit {
        reset()
        if (let Some(v) <- data) {
            if (!v.isEmpty()) {
                for (value in v) {
                    addToBlackList(value)
                }
            }
        }
    }

    public override func reset(): Unit {
        mBlackList.clear()
    }
}

/**
 * 根据用户Id黑名单过滤
 *
 */
public class UserIdFilter <: UserFilter<Int64> {
    public override func filter(danmaku: ?BaseDanmaku, _: Int64, _: Int64, _: DanmakuTimer,
        _: Bool, _: DanmakuContext): Bool {
        let filtered: Bool = danmaku.isSome() && mBlackList.contains(danmaku().userId)
        if (filtered) {
            danmaku().mFilterParam |= DanmakuFilters.FILTER_TYPE_USER_ID
        }
        return filtered
    }
}

/**
 * 根据用户hash黑名单过滤
 *
 */
public class UserHashFilter <: UserFilter<String> {
    public override func filter(danmaku: ?BaseDanmaku, _: Int64, _: Int64, _: DanmakuTimer,
        _: Bool, _: DanmakuContext): Bool {
        let filtered: Bool = danmaku.isSome() && mBlackList.contains(danmaku().userHash)
        if (filtered) {
            danmaku().mFilterParam |= DanmakuFilters.FILTER_TYPE_USER_HASH
        }
        return filtered
    }
}

/**
 * 屏蔽游客弹幕
 *
 */
public class GuestFilter <: BaseDanmakuFilter<Bool> {
    private var mBlock: Bool = false

    public override func filter(danmaku: ?BaseDanmaku, _: Int64, _: Int64, _: DanmakuTimer,
        _: Bool, _: DanmakuContext): Bool {
        if (let Some(v) <- danmaku) {
            let filtered: Bool = mBlock && v.isGuest
            if (filtered) {
                v.mFilterParam |= DanmakuFilters.FILTER_TYPE_USER_GUEST
            }
            return filtered
        }
        return false
    }

    public override func setData(data: ?Bool): Unit {
        if (let Some(v) <- data) {
            mBlock = v
        }
    }

    public override func reset(): Unit {
        mBlock = false
    }
}

public class DuplicateMergingFilter <: BaseDanmakuFilter<Unit> {
    protected let blockedDanmakus: IDanmakus = Danmakus(ST_BY_LIST)
    protected let currentDanmakus: HashMap<String, BaseDanmaku> = HashMap<String, BaseDanmaku>()
    private let passedDanmakus: IDanmakus = Danmakus(ST_BY_LIST)
    let mtx = ReentrantMutex()

    private func removeTimeoutDanmakus(danmakus: IDanmakus, limitTime: Int64): Unit {
        danmakus.forEachSync(Remove(limitTime))
    }

    private func removeTimeoutDanmakus(danmakus: HashMap<String, BaseDanmaku>, limitTime: Int64): Unit {
        let it: HashMapIterator<String, BaseDanmaku> = danmakus.iterator()
        let startTime: Int64 = SystemClock.uptimeMillis()
        while (true) {
            try {
                let entry = it.next()
                if (let Some(v) <- entry) {
                    let item: BaseDanmaku = v[1]
                    if (item.isTimeOut()) {
                        it.remove()
                    } else {
                        break
                    }
                }
            } catch (e: Exception) {
                break
            }
            if (SystemClock.uptimeMillis() - startTime > limitTime) {
                break
            }
        }
    }

    public func needFilter(danmaku: BaseDanmaku, _: Int64, _: Int64, _: DanmakuTimer,
        _: Bool): Bool {
        synchronized(mtx) {
            removeTimeoutDanmakus(blockedDanmakus, 2)
            removeTimeoutDanmakus(passedDanmakus, 2)
            removeTimeoutDanmakus(currentDanmakus, 3)
            var isOutside: Bool = danmaku.isOutside()
            if (blockedDanmakus.contains(danmaku) && !isOutside) {
                return true
            }
            if (passedDanmakus.contains(danmaku)) {
                return false
            }
            if (currentDanmakus.contains(danmaku.text)) {
                currentDanmakus.add(danmaku.text, danmaku)
                blockedDanmakus.removeItem(danmaku)
                blockedDanmakus.addItem(danmaku)
                return true
            } else {
                currentDanmakus.add(danmaku.text, danmaku)
                passedDanmakus.addItem(danmaku)
                return false
            }
        }
    }

    public override func filter(danmaku: ?BaseDanmaku, index: Int64, totalsizeInScreen: Int64, timer: DanmakuTimer,
        fromCachingTask: Bool, _: DanmakuContext): Bool {
        if (let Some(v) <- danmaku) {
            let filtered: Bool = needFilter(v, index, totalsizeInScreen, timer, fromCachingTask)
            if (filtered) {
                v.mFilterParam |= DanmakuFilters.FILTER_TYPE_DUPLICATE_MERGE
            }
            return filtered
        }
        return false
    }

    public override func setData(_: ?Unit): Unit {}

    public override func reset(): Unit {
        synchronized(mtx) {
            passedDanmakus.clear()
            blockedDanmakus.clear()
            currentDanmakus.clear()
        }
    }

    public override func clear(): Unit {
        reset()
    }
}

public class MaximumLinesFilter <: BaseDanmakuFilter<HashMap<Int64, Int64>> {
    private var mMaximumLinesPairs: HashMap<Int64, Int64> = HashMap<Int64, Int64>()

    public override func filter(danmaku: ?BaseDanmaku, lines: Int64, _: Int64, _: DanmakuTimer,
        _: Bool, _: DanmakuContext): Bool {
        var filtered: Bool = false
        if (!mMaximumLinesPairs.isEmpty() && danmaku.isSome()) {
            let maxLines: ?Int64 = mMaximumLinesPairs.get(danmaku().getType())
            filtered = if (let Some(v) <- maxLines) {
            	lines >= v
            } else {
            	false
            }
            if (filtered) {
                danmaku().mFilterParam |= DanmakuFilters.FILTER_TYPE_MAXIMUM_LINES
            }
        }
        return filtered
    }

    public override func setData(data: ?HashMap<Int64, Int64>): Unit {
        if (let Some(v) <- data) {
            mMaximumLinesPairs = v
        }
    }

    public override func reset(): Unit {
        mMaximumLinesPairs = HashMap<Int64, Int64>()
    }
}

public class OverlappingFilter <: BaseDanmakuFilter<HashMap<Int64, Bool>> {
    private var mEnabledPairs: HashMap<Int64, Bool> = HashMap<Int64, Bool>()

    public override func filter(danmaku: ?BaseDanmaku, _: Int64, _: Int64, _: DanmakuTimer,
        willHit: Bool, _: DanmakuContext): Bool {
        var filtered: Bool = false
        if (!mEnabledPairs.isEmpty() && danmaku.isSome()) {
            let enabledValue: ?Bool = mEnabledPairs.get(danmaku().getType())
            filtered = enabledValue.isSome() && enabledValue() && willHit
            if (filtered) {
                danmaku().mFilterParam |= DanmakuFilters.FILTER_TYPE_OVERLAPPING
            }
        }
        return filtered
    }

    public override func setData(data: ?HashMap<Int64, Bool>): Unit {
        if (let Some(v) <- data) {
            mEnabledPairs = v
        }
    }

    public override func reset(): Unit {
        mEnabledPairs = HashMap<Int64, Bool>()
    }
}

public class DanmakuFilters {
    public static let FILTER_TYPE_TYPE: Int64 = 1
    public static let FILYER_TYPE_QUANTITY: Int64 = 2
    public static let FILTER_TYPE_ELAPSED_TIME: Int64 = 4
    public static let FILTER_TYPE_TEXTCOLOR: Int64 = 8
    public static let FILTER_TYPE_USER_ID: Int64 = 16
    public static let FILTER_TYPE_USER_HASH: Int64 = 32
    public static let FILTER_TYPE_USER_GUEST: Int64 = 64
    public static let FILTER_TYPE_DUPLICATE_MERGE: Int64 = 128
    public static let FILTER_TYPE_MAXIMUM_LINES: Int64 = 256
    public static let FILTER_TYPE_OVERLAPPING: Int64 = 512

    public static let TAG_TYPE_DANMAKU_FILTER: String = "1010_Filter"
    public static let TAG_QUANTITY_DANMAKU_FILTER: String = "1011_Filter"
    public static let TAG_ELAPSED_TIME_FILTER: String = "1012_Filter"
    public static let TAG_TEXT_COLOR_DANMAKU_FILTER: String = "1013_Filter"
    public static let TAG_USER_ID_FILTER: String = "1014_Filter"
    public static let TAG_USER_HASH_FILTER: String = "1015_Filter"
    public static let TAG_GUEST_FILTER: String = "1016_Filter"
    public static let TAG_DUPLICATE_FILTER: String = "1017_Filter"
    public static let TAG_MAXIMUN_LINES_FILTER: String = "1018_Filter"
    public static let TAG_OVERLAPPING_FILTER: String = "1019_Filter"
    public static let TAG_PRIMARY_CUSTOM_FILTER: String = "2000_Primary_Custom_Filter"
    public static let filterException: Exception = Exception("not support this filter tag")

    private var filters: HashMap<String, IDanmakuFilter> = HashMap<String, IDanmakuFilter>()
    private var filtersSecondary: HashMap<String, IDanmakuFilter> = HashMap<String, IDanmakuFilter>()
    var mFilterArray: ArrayList<IDanmakuFilter> = ArrayList<IDanmakuFilter>()
    var mFilterArraySecondary: ArrayList<IDanmakuFilter> = ArrayList<IDanmakuFilter>()

    public func filter(danmaku: ?BaseDanmaku, index: Int64, totalsizeInScreen: Int64, timer: DanmakuTimer,
        fromCachingTask: Bool, context: DanmakuContext): Unit {
        if (let Some(v) <- danmaku) {
            for (f in mFilterArray) {
                let filtered: Bool = f.filter(v, index, totalsizeInScreen, timer,
                    fromCachingTask, context)
                v.filterResetFlag = context.mGlobalFlagValues.FILTER_RESET_FLAG
                if (filtered) {
                    break
                }
            }
        }
    }

    public func filterSecondary(danmaku: ?BaseDanmaku, lines: Int64, totalsizeInScreen: Int64, timer: DanmakuTimer,
        willHit: Bool, context: DanmakuContext): Bool {
        if (let Some(v) <- danmaku) {
            for (f in mFilterArraySecondary) {
                let filtered: Bool = f.filter(v, lines, totalsizeInScreen, timer, willHit,
                    context)
                v.filterResetFlag = context.mGlobalFlagValues.FILTER_RESET_FLAG
                if (filtered) {
                    return true
                }
            }
        }
        return false
    }

    public func get(tag: String): ?IDanmakuFilter {
        return get(tag, true)
    }

    public func get(tag: String, primary: Bool): ?IDanmakuFilter {
        var f: ?IDanmakuFilter = if (primary) {
            filters.get(tag)
        } else {
            filtersSecondary.get(tag)
        }
        if (f.isNone()) {
            f = registerFilter(tag, primary)
        }
        return f
    }

    public func registerFilter(tag: String): ?IDanmakuFilter {
        return registerFilter(tag, true)
    }

    public func registerFilter(tag: String, primary: Bool): ?IDanmakuFilter {
        if (tag == "") {
            return None
        }
        let size = filters.size
        var filter: ?IDanmakuFilter = filters.get(tag)
        if (filter.isNone()) {
            if (TAG_TYPE_DANMAKU_FILTER == tag) {
                let f = TypeDanmakuFilter()
                 f.setData(Option.None)
                filter = f
            } else if (TAG_QUANTITY_DANMAKU_FILTER == tag) {
                let f = QuantityDanmakuFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_ELAPSED_TIME_FILTER == tag) {
                let f = ElapsedTimeFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_TEXT_COLOR_DANMAKU_FILTER == tag) {
                let f = TextColorFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_USER_ID_FILTER == tag) {
                let f = UserIdFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_USER_HASH_FILTER == tag) {
                let f = UserHashFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_GUEST_FILTER == tag) {
                let f = GuestFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_DUPLICATE_FILTER == tag) {
                let f = DuplicateMergingFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_MAXIMUN_LINES_FILTER == tag) {
                let f = MaximumLinesFilter()
                f.setData(Option.None)
                filter = f
            } else if (TAG_OVERLAPPING_FILTER == tag) {
                let f = OverlappingFilter()
                f.setData(Option.None)
                filter = f
            }
        }
        if (filter.isNone()) {
            return None
        }
        if (primary) {
            filters.add(tag, filter())
            let values = filters.values()
            for (v in values) {
                mFilterArray.add(v)
            }
        } else {
            filtersSecondary.add(tag, filter())
            let values = filtersSecondary.values()
            for (v in values) {
                mFilterArraySecondary.add(v)
            }
        }
        return filter
    }

    public func registerFilter(filter: BaseDanmakuFilter<Any>): Unit {
        filters.add(TAG_PRIMARY_CUSTOM_FILTER + "_" + filter.hashCode().toString(), filter)
        let values = filters.values()
        for (v in values) {
            mFilterArray.add(v)
        }
    }

    public func unregisterFilter(tag: String): Unit {
        unregisterFilter(tag, true)
    }

    public func unregisterFilter(tag: String, primary: Bool): Unit {
        let f: ?IDanmakuFilter = if (primary) {
            filters.remove(tag)
        } else {
            filtersSecondary.remove(tag)
        }
        if (let Some(v: IDanmakuFilter) <- f) {
            v.clear()
            if (primary) {
                let values = filters.values()
                for (value in values) {
                    mFilterArray.add(value)
                }
            } else {
                let values = filtersSecondary.values()
                for (value in values) {
                    mFilterArraySecondary.add(value)
                }
            }
        }
    }

    public func unregisterFilter(filter: BaseDanmakuFilter<Any>): Unit {
        filters.remove(TAG_PRIMARY_CUSTOM_FILTER + "_" + filter.hashCode().toString())
        let values = filters.values()
        for (value in values) {
            mFilterArray.add(value)
        }
    }

    public func clear(): Unit {
        for (f in mFilterArray) {
            f.clear()
        }
        for (k in mFilterArraySecondary) {
            k.clear()
        }
    }

    public func reset(): Unit {
        for (f in mFilterArray) {
            f.reset()
        }
        for (k in mFilterArraySecondary) {
            k.reset()
        }
    }

    public func release(): Unit {
        clear()
        filters.clear()
        mFilterArray = ArrayList<IDanmakuFilter>()
        filtersSecondary.clear()
        mFilterArraySecondary = ArrayList<IDanmakuFilter>()
    }

}

class Remove <: Consumer<BaseDanmaku, Unit> {
    private var limitTime: Int64
    init(limitTime: Int64) {
        super()
        this.limitTime = limitTime
    }
    let startTime: Int64 = SystemClock.uptimeMillis()

    public override func accept(item: BaseDanmaku): Int64 {
        try {
            if (SystemClock.uptimeMillis() - startTime > limitTime) {
                return ACTION_BREAK
            }
            if (item.isTimeOut()) {
                return ACTION_REMOVE
            } else {
                return ACTION_BREAK
            }
        } catch (e: Exception) {
            return ACTION_BREAK
        }
    }
}


