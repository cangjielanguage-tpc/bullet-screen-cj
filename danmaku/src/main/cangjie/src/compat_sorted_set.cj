/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

protected class SortedSet<T> where T <: Comparable<T> & Equatable<T> & ToString {
    let arr: ArrayList<T>

    public init() {
        arr = ArrayList<T>()
    }

    public func binaryInsert(item: T): Int64 {
        if (arr.size == 0) {
            arr.append(item)
            return 1
        }
        var startIndex: Int64 = 0
        var endIndex: Int64 = arr.size - 1
        var middleIndex: Int64
        var cmp: Int64
        while (startIndex <= endIndex) {
            middleIndex = Int64(floor(Float64((startIndex + endIndex) / 2)))
            match (item.compare(arr[middleIndex])) {
                case EQ => return 0
                case GT => startIndex = middleIndex + 1
                case LT => endIndex = middleIndex - 1
            }
        }
        arr[startIndex] = item
        return 1
    }

    public func subSet(fromElement: T, toElement: T): SortedSet<T> {
        if (fromElement > toElement) {
            throw IllegalArgumentException("IllegalArguments: fromElement or toElement")
        }
        var indexFrom: Int64 = arr.size
        var indexTo: Int64 = -1
        for (i in 0..arr.size where fromElement < arr[i]) {
            indexFrom = i
            break
        }
        for (i in arr.size - 1..=indexFrom : -1 where toElement > arr[i]) {
            indexTo = i
            break
        }
        let result = SortedSet<T>()
        if (indexTo >= indexFrom) {
            result.arr.appendAll(arr[indexFrom..indexTo + 1])
        }
        return result
    }

    public func toString(): String {
        arr.toString()
    }
}
