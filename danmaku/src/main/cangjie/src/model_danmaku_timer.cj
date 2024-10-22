/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public class DanmakuTimer {
    public var currMillisecond: Int64 = 0
    public var lastInterval: Int64 = 0

    public init(currMillisecond: ?Int64) {
        if (let Some(v) <- currMillisecond) {
            update(v)
        }
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
