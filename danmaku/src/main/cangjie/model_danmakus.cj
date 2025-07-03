/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class Danmakus <: IDanmakus {
    public var items: SortedSet<BaseDanmaku>
    private var subItems: ?Danmakus = None
    private var startItem: ?BaseDanmaku = None
    private var endItem: ?BaseDanmaku = None
    private var endSubItem: ?BaseDanmaku = None
    private var startSubItem: ?BaseDanmaku = None
    private let mSize: AtomicInt64 = AtomicInt64(0)
    private var mSortType: Int64 = ST_BY_TIME
    private var mComparator: ?BaseComparator = None
    public var mDuplicateMergingEnabled: Bool = true

    public init() {
        this(ST_BY_TIME, false)
    }
    public init(sortType: Int64) {
        this(sortType, false)
    }

    public init(items: Collection<BaseDanmaku> ) {
        this.items = SortedSet<BaseDanmaku>()
        this.setItems(items)
    }

    public init(duplicateMergingEnabled: Bool) {
        this(ST_BY_TIME, duplicateMergingEnabled)
    }

    public init(sortType: Int64, duplicateMergingEnabled: Bool) {
        this(sortType, duplicateMergingEnabled, Option<BaseComparator>.None)
    }

    public init(sortType: Int64, duplicateMergingEnabled: Bool, baseComparator: ?BaseComparator) {
        var comparator: ?BaseComparator = None
        if (sortType == ST_BY_TIME) {
            comparator = if (baseComparator.isNone()) {
               TimeComparator(duplicateMergingEnabled)
            } else {
                baseComparator
            }
        } else if (sortType == ST_BY_YPOS) {
            comparator = YPosComparator(duplicateMergingEnabled)
        } else if (sortType == ST_BY_YPOS_DESC) {
            comparator = YPosDescComparator(duplicateMergingEnabled)
        }
        if (sortType == ST_BY_LIST) {
            items = SortedSet<BaseDanmaku>()
        } else {
            mDuplicateMergingEnabled = duplicateMergingEnabled
            if (let Some(v) <- comparator) {
                v.setDuplicateMergingEnabled(duplicateMergingEnabled)
                items = SortedSet<BaseDanmaku>(v.compare)
                mComparator = v
            } else {
                throw NoneValueException()
            }
        }
        mSortType = sortType
        mSize.store(0)
    }

    public func setItems(i: Collection<BaseDanmaku>): Unit {
        if (mDuplicateMergingEnabled && mSortType != ST_BY_LIST) {
            this.items.clear();
            this.items.appendAll(items);
            items = this.items;
        } else {
            this.items = (i as SortedSet<BaseDanmaku>).getOrThrow()
        }

        mSize.store(if (items.isEmpty()) {
            0
        } else {
            items.size
        })
    }

    public override func addItem(item: BaseDanmaku): Bool {
        items.add(item)
        mSize.fetchAdd(1)
        return true
    }

    public override func removeItem(item: ?BaseDanmaku): Bool {
        if (let Some(v) <- item) {
            if (v.isOutside()) {
                v.setVisibility(false)
            }
            if (items.remove(v)) {
                mSize.fetchSub(1)
                return true
            }
        }
        return false
    }

    private func subset(startTime: Int64, endTime: Int64): ?SortedSet<BaseDanmaku> {
        if (mSortType == ST_BY_LIST || items.isEmpty() || items.size == 0) {
            return None
        }
        if (subItems.isNone()) {
            subItems = Danmakus(mDuplicateMergingEnabled)
        }
        if (startSubItem.isNone()) {
            startSubItem = createItem("start")
        }
        if (endSubItem.isNone()) {
            endSubItem = createItem("end")
        }
        startSubItem().setTime(startTime)
        endSubItem().setTime(endTime)
        return items.subSet(startSubItem(), endSubItem())
    }

    public override func subnew(startTime: Int64, endTime: Int64): ?IDanmakus {
        let subSet: ?SortedSet<BaseDanmaku> = subset(startTime, endTime)
        if (let Some(v) <- subSet) {
            return Danmakus(v)
        } else {
            return None
        }
    }

    public override func sub(startTime: Int64, endTime: Int64): ?IDanmakus {
        if (items.isEmpty() || items.size == 0) {
            return None
        }
        if (subItems.isNone()) {
            if (mSortType == ST_BY_LIST) {
                subItems = Danmakus(ST_BY_LIST)
                subItems?.setItems(items)
            } else {
                subItems = Danmakus(mDuplicateMergingEnabled)
            }
        }
        if (mSortType == ST_BY_LIST) {
            return (subItems ?? None)
        }
        if (startItem.isNone()) {
            startItem = createItem("start")
        }
        if (endItem.isNone()) {
            endItem = createItem("end")
        }
        if (subItems.isSome()) {
            let dtime: Int64 = startTime - startItem.getOrThrow().getActualTime()
            if (endTime <= endItem.getOrThrow().getActualTime() && dtime >= 0) {
                return (subItems ?? None)
            }
        }
        startItem?.setTime(startTime)
        endItem?.setTime(endTime)
        subItems?.setItems(items.subSet(startItem.getOrThrow(), endItem.getOrThrow()))
        return (subItems ?? None)
    }

    private func createItem(text: String): BaseDanmaku {
        return Danmaku(text)
    }

    public override func size(): Int64 {
        return mSize.load()
    }

    public override func clear(): Unit {
        if (!items.isEmpty()) {
            items.clear()
            mSize.store(0)
        }
        if (subItems.isSome()) {
            subItems = None
            startItem = createItem("start")
            endItem = createItem("end")
        }
    }

    public override func first(): ?BaseDanmaku {
        return items.getFirst()
    }

    public override func last(): ?BaseDanmaku {
        return items.getLast()
    }

    public override func contains(item: BaseDanmaku): Bool {
        return items.contains(item)
    }

    public override func isEmpty(): Bool {
        return items.isEmpty() || items.size == 0
    }

    private func setDuplicateMergingEnabled(enable: Bool): Unit {
        mComparator().setDuplicateMergingEnabled(enable)
        mDuplicateMergingEnabled = enable
    }

    public override func setSubItemsDuplicateMergingEnabled(enable: Bool): Unit {
        mDuplicateMergingEnabled = enable
        startItem = None
        endItem = None
        if (subItems.isNone()) {
            subItems = Danmakus(enable)
        }
        this.subItems?.setDuplicateMergingEnabled(enable)
    }

    public override func getCollection(): SortedSet<BaseDanmaku> {
        return items
    }

    public override func forEachSync(consumer: Consumer<BaseDanmaku, RetainerState>): Unit {
        forEach<RetainerState>(consumer)
    }
    public override func forEachSync(consumer: Consumer<BaseDanmaku, Unit>): Unit {
        forEach<Unit>(consumer)
    }

    public override func forEach(consumer: Consumer<BaseDanmaku, Unit>): Unit {
        forEach<Unit>(consumer)
    }

    public override func forEach(consumer: Consumer<BaseDanmaku, RetainerState>): Unit {
        forEach<RetainerState>(consumer)
    }

    private func forEach<T>(consumer: Consumer<BaseDanmaku, T>): Unit {
        consumer.before()
        var index = -1
        for (v in this.items) {
            index ++
            let action: Int64 = consumer.accept(v)
            if (action == ACTION_BREAK) {
                break
            } else if (action == ACTION_REMOVE) {
                this.items.remove(index)
                index--
                mSize.fetchSub(1)
            } else if (action == ACTION_REMOVE_AND_BREAK) {
                this.items.remove(index)
                index--
                mSize.fetchSub(1)
                break
            }
        }
        consumer.after()
    }
}
