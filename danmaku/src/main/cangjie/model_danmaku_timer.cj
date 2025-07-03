/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class DanmakuTimer {
    private var currMillisecond_: AtomicInt64 = AtomicInt64(0)
    let lock: ReentrantMutex = ReentrantMutex()
    public prop currMillisecond: Int64 {
        get () {
            return currMillisecond_.load()
        }
    }
    public var lastInterval: Int64 = 0



    public init() {}
    public init(currMillisecond: Int64) {
        update(currMillisecond)
    }

    public func update(curr: Int64): Int64 {
        lastInterval = curr - currMillisecond_.load()
        currMillisecond_.store(curr)
        return lastInterval
    }

    public func add(mills: Int64): Int64 {
        return update(currMillisecond_.load() + mills)
    }

    public func getLastInterval(): Int64 {
        return lastInterval
    }
}
