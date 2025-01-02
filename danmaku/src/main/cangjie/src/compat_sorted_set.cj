/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public class SortedSet<T> where T <: BaseDanmaku {
    public var arr: ArrayList<T> = ArrayList<T>()
    var comparator: BaseComparator = BaseComparator()

    public init() {}

    public init(comparator: BaseComparator) {
        this.comparator = comparator
    }

    public func push(items: ArrayList<T>): Int64 {
        var count: Int64 = 0
        for (item in items) {
            count += binaryInsert(item)
        }
        return count
    }

    public func binaryInsert(item: T): Int64 {
        if (arr.size == 0) {
            arr.append(item)
            return 1
        }
        var startIndex: Int64 = 0
        var endIndex: Int64 = arr.size - 1
        var middleIndex: Int64
        var cmp: Ordering
        while (startIndex <= endIndex) {
            middleIndex = Int64(floor(Float64((startIndex + endIndex) / 2)))
            cmp = comparator.compare(item, arr[middleIndex])
            match (cmp) {
                case EQ => return 0
                case GT => startIndex = middleIndex + 1
                case LT => endIndex = middleIndex - 1
            }
        }
        arr[startIndex] = item
        return 1
    }

    public func subSet(fromElement: T, toElement: T): SortedSet<T> {
        if (comparator.compare(fromElement, toElement) == Ordering.GT) {
            throw IllegalArgumentException("IllegalArguments: fromElement or toElement")
        }
        var indexFrom: Int64 = arr.size
        var indexTo: Int64 = -1
        for (i in 0..arr.size where fromElement < arr[i]) {
            if (comparator.compare(fromElement, arr[i]) == Ordering.LT) {
                indexFrom = i
                break
            }
        }
        for (i in arr.size - 1..=indexFrom : -1 where toElement > arr[i]) {
            if (comparator.compare(toElement, arr[i]) == Ordering.GT) {
                indexTo = i
                break
            }
        }
        let result = SortedSet<T>(comparator)
        if (indexTo >= indexFrom) {
            result.arr.appendAll(arr[indexFrom..indexTo + 1])
        }
        return result
    }
}
