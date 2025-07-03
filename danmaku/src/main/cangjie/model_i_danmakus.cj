/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public let ST_BY_TIME: Int64 = 0
public let ST_BY_YPOS: Int64 = 1
public let ST_BY_YPOS_DESC: Int64 = 2

/**
 * this type is used to iterate/remove/insert elements, not support sub/subnew
 */
public let ST_BY_LIST: Int64 = 4

public interface IDanmakus {
    func addItem(item: BaseDanmaku): Bool

    func removeItem(item: ?BaseDanmaku): Bool

    func subnew(startTime: Int64, endTime: Int64): ?IDanmakus

    func sub(startTime: Int64, endTime: Int64): ?IDanmakus

    func size(): Int64

    func clear(): Unit

    func first(): ?BaseDanmaku

    func last(): ?BaseDanmaku

    func contains(item: BaseDanmaku): Bool

    func isEmpty(): Bool

    func setSubItemsDuplicateMergingEnabled(enable: Bool): Unit

    func getCollection(): SortedSet<BaseDanmaku>

    func forEachSync(consumer: Consumer<BaseDanmaku, Unit>): Unit
    func forEachSync(consumer: Consumer<BaseDanmaku, RetainerState>): Unit

    func forEach(consumer: Consumer<BaseDanmaku, Unit>): Unit
    func forEach(consumer: Consumer<BaseDanmaku, RetainerState>): Unit
}

let ACTION_CONTINUE: Int64 = 0
let ACTION_BREAK: Int64 = 1
let ACTION_REMOVE: Int64 = 2
let ACTION_REMOVE_AND_BREAK: Int64 = 3
public abstract class Consumer<Progress, Result> {

    /**
     * Performs this operation on the given argument.
     *
     * @param t the input argument
     * @return next action of the loop
     *
     * @see #ACTION_CONTINUE
     * @see #ACTION_BREAK
     * @see #ACTION_REMOVE
     */
    public open func accept(item: Progress): Int64

    public open func before(): Unit {}

    public open func after(): Unit {}

    public open func result(): ?Result {
        return None
    }
}

public open class DefaultConsumer<Progress> <: Consumer<Progress, Unit> {
    var fn: (Progress) -> Int64
    init(f: (Progress) -> Int64) {
        this.fn = f
    }

    public open func accept(item: Progress): Int64 {
        return fn(item)
    }
}

public open class BaseComparator {
    protected var mDuplicateMergingEnable: Bool = true

    init(duplicateMergingEnabled!: Bool = true) {
        mDuplicateMergingEnable = duplicateMergingEnabled
    }

    public func setDuplicateMergingEnabled(enable: Bool): Unit {
        mDuplicateMergingEnable = enable
    }

    public open func compare(obj1: BaseDanmaku, obj2: BaseDanmaku): Ordering {
        if (mDuplicateMergingEnable && DanmakuUtils.isDuplicate(obj1, obj2)) {
            return Ordering.EQ
        }
        return DanmakuUtils.compare(obj1, obj2)
    }
}

public class TimeComparator <: BaseComparator {
    init(duplicateMergingEnabled: Bool) {
        super(duplicateMergingEnabled: duplicateMergingEnabled)
    }

    public override func compare(obj1: BaseDanmaku, obj2: BaseDanmaku): Ordering {
        return super.compare(obj1, obj2)
    }
}

public class YPosComparator <: BaseComparator {
    init(duplicateMergingEnabled: Bool) {
        super(duplicateMergingEnabled: duplicateMergingEnabled)
    }

    public override func compare(obj1: BaseDanmaku, obj2: BaseDanmaku): Ordering {
        if (mDuplicateMergingEnable && DanmakuUtils.isDuplicate(obj1, obj2)) {
            return Ordering.EQ
        }
        if (obj1.getTop() > obj2.getTop()) {
            return Ordering.GT
        } else if (obj1.getTop() < obj2.getTop()) {
            return Ordering.LT
        } else {
            return Ordering.EQ
        }
    }
}

public class YPosDescComparator <: BaseComparator {
    init(duplicateMergingEnabled: Bool) {
        super(duplicateMergingEnabled: duplicateMergingEnabled)
    }

    public override func compare(obj1: BaseDanmaku, obj2: BaseDanmaku): Ordering {
        if (mDuplicateMergingEnable && DanmakuUtils.isDuplicate(obj1, obj2)) {
            return Ordering.EQ
        }
        if (obj2.getTop() > obj1.getTop()) {
            return Ordering.GT
        } else if (obj2.getTop() < obj1.getTop()) {
            return Ordering.LT
        } else {
            return Ordering.EQ
        }
    }
}
