/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

internal class DanmakusArgs {
    var items: SortedSet<BaseDanmaku> = SortedSet<BaseDanmaku>()
    var sortType: Int64 = 0
    var duplicateMergingEnabled: Bool = false
    var baseComparator: ?BaseComparator = None

    init(items!: SortedSet<BaseDanmaku> = SortedSet<BaseDanmaku>(), sortType!: Int64 = 0,
        duplicateMergingEnabled!: Bool = false, baseComparator!: ?BaseComparator = None) {
        this.items = items
        this.sortType = sortType
        this.duplicateMergingEnabled = duplicateMergingEnabled
        this.baseComparator = baseComparator
    }
}

public class Danmakus <: IDanmakus {
    public var items: SortedSet<BaseDanmaku> = SortedSet<BaseDanmaku>()
    private var subItems: ?Danmakus = None
    private var startItem: ?BaseDanmaku = None
    private var endItem: ?BaseDanmaku = None
    private var endSubItem: ?BaseDanmaku = None
    private var startSubItem: ?BaseDanmaku = None
    private var mSize: Int64 = 0
    private var mSortType: Int64 = ST_BY_TIME
    private var mComparator: ?BaseComparator = None
    public var mDuplicateMergingEnabled: Bool = true

    init(items: SortedSet<BaseDanmaku>) {
        setItems(items)
    }

    init(args: DanmakusArgs) {
        if (!args.items.arr.isEmpty()) {
            setItems(args.items)
        } else {
            if (args.sortType == 0) {
                args.sortType = ST_BY_TIME
            }
            if (args.duplicateMergingEnabled == false) {
                args.duplicateMergingEnabled = false
            }
            if (args.baseComparator.isNone()) {
                args.baseComparator = None
            }
            var comparator: ?BaseComparator = None
            if (args.sortType == ST_BY_TIME) {
                comparator = if (let Some(v) <- args.baseComparator) {
                    v
                } else {
                    TimeComparator(args.duplicateMergingEnabled)
                }
            } else if (args.sortType == ST_BY_YPOS) {
                comparator = YPosComparator(args.duplicateMergingEnabled)
            } else if (args.sortType == ST_BY_YPOS_DESC) {
                comparator = YPosDescComparator(args.duplicateMergingEnabled)
            }
            if (args.sortType == ST_BY_LIST) {
                items = SortedSet<BaseDanmaku>()
            } else {
                mDuplicateMergingEnabled = args.duplicateMergingEnabled
                if (let Some(v) <- comparator) {
                    v.setDuplicateMergingEnabled(args.duplicateMergingEnabled)
                    items = SortedSet<BaseDanmaku>(v)
                    mComparator = v
                }
            }
            mSortType = args.sortType
            mSize = 0
        }
    }

    public func setItems(i: SortedSet<BaseDanmaku>): Unit {
        var optSet: SortedSet<BaseDanmaku> = i
        if (mDuplicateMergingEnabled && mSortType != ST_BY_LIST) {
            items.arr.clear()
            items.arr.appendAll(optSet.arr)
            optSet = items
        } else {
            items = optSet
        }
        mSize = if (items.arr.isEmpty()) {
            0
        } else {
            items.arr.size
        }
    }

    public override func addItem(item: BaseDanmaku): Bool {
        if (!items.arr.isEmpty()) {
            try {
                if (items.binaryInsert(item) > 0) {
                    mSize++
                    return true
                }
            } catch (e: Exception) {}
        }
        return false
    }

    public override func removeItem(item: ?BaseDanmaku): Bool {
        if (let Some(v) <- item) {
            if (v.isOutside()) {
                v.setVisibility(false)
            }
            if (let Some(index) <- items.arr.toArray().indexOf(v)) {
                items.arr.remove(index)
                mSize--
                return true
            }
        }
        return false
    }

    private func subset(startTime: Int64, endTime: Int64): ?SortedSet<BaseDanmaku> {
        if (mSortType == ST_BY_LIST || items.arr.isEmpty() || items.arr.size == 0) {
            return None
        }
        if (subItems.isNone()) {
            subItems = Danmakus(DanmakusArgs(duplicateMergingEnabled: mDuplicateMergingEnabled))
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
        if (items.arr.isEmpty() || items.arr.size == 0) {
            return None
        }
        if (subItems.isNone()) {
            if (mSortType == ST_BY_LIST) {
                let subItems = Danmakus(DanmakusArgs(sortType: ST_BY_LIST))
                subItems.setItems(items)
            } else {
                subItems = Danmakus(DanmakusArgs(duplicateMergingEnabled: mDuplicateMergingEnabled))
            }
        }
        if (mSortType == ST_BY_LIST) {
            return subItems()
        }
        if (startItem.isNone()) {
            startItem = createItem("start")
        }
        if (endItem.isNone()) {
            endItem = createItem("end")
        }
        if (let Some(v) <- subItems) {
            let dtime: Int64 = startTime - startItem().getActualTime()
            if (dtime >= 0 && endTime <= endItem().getActualTime()) {
                return v
            }
        }
        startItem().setTime(startTime)
        endItem().setTime(endTime)
        subItems().setItems(items.subSet(startItem(), endItem()))
        return subItems()
    }

    private func createItem(text: String): BaseDanmaku {
        return Danmaku(text)
    }

    public override func size(): Int64 {
        return mSize
    }

    public override func clear(): Unit {
        if (!items.arr.isEmpty()) {
            items.arr.clear()
            mSize = 0
        }
        if (subItems.isSome()) {
            subItems = None
            startItem = createItem("start")
            endItem = createItem("end")
        }
    }

    public override func first(): ?BaseDanmaku {
        if (!items.arr.isEmpty() && items.arr.size != 0) {
            return items.arr[0]
        }
        return None
    }

    public override func last(): ?BaseDanmaku {
        if (!items.arr.isEmpty() && items.arr.size != 0) {
            return items.arr[items.arr.size - 1]
        }
        return None
    }

    public override func contains(item: BaseDanmaku): Bool {
        return !items.arr.isEmpty() && items.arr.toArray().indexOf(item).isSome()
    }

    public override func isEmpty(): Bool {
        return items.arr.isEmpty() || items.arr.size == 0
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
            subItems = Danmakus(DanmakusArgs(duplicateMergingEnabled: enable))
        }
        subItems().setDuplicateMergingEnabled(enable)
    }

    public override func getCollection(): SortedSet<BaseDanmaku> {
        return items
    }

    public override func forEachSync(consumer: Consumer<BaseDanmaku, Any>): Unit {
        forEach(consumer)
    }

    public override func forEach(consumer: Consumer<BaseDanmaku, Any>): Unit {
        consumer.before()
        for (i in 0..items.arr.size) {
            let next: BaseDanmaku = items.arr[i]
            let action: Int64 = consumer.accept(next)
            if (action == DefaultConsumer<Progress>.ACTION_BREAK) {
                break
            } else if (action == DefaultConsumer<Progress>.ACTION_REMOVE) {
                items.arr.remove(i)
                mSize--
            } else if (action == DefaultConsumer<Progress>.ACTION_REMOVE_AND_BREAK) {
                items.arr.remove(i)
                mSize--
                break
            }
        }
        consumer.after()
    }
}
