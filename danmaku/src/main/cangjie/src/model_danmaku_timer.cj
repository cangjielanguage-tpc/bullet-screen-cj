/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

let rand = AtomicInt64(0)

public class DanmakuTimer {
    public let r = rand.fetchAdd(1)
    public var currMillisecond: Int64 = 0
    public var lastInterval: Int64 = 0

    public init() {}
    public init(currMillisecond: Int64) {
        update(currMillisecond)
    }

    public func update(curr: Int64): Int64 {
        lastInterval = curr - currMillisecond
        currMillisecond = curr
        return lastInterval
    }

    public func add(mills: Int64): Int64 {
        return update(currMillisecond + mills)
    }

    public func getLastInterval(): Int64 {
        return lastInterval
    }
}
