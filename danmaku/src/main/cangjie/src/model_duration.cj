/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public class DanmakuDuration {
    private var mInitialDuration: Int64

    private var factor: Float64 = 1.0

    public var value: Int64

    public init(initialDuration: Int64) {
        mInitialDuration = initialDuration
        value = initialDuration
    }

    public func setValue(initialDuration: Int64): Unit {
        mInitialDuration = initialDuration
        value = (mInitialDuration * Int64(factor))
    }

    public func setFactor(f: Float64): Unit {
        if (factor != f) {
            factor = f
            value = (mInitialDuration * Int64(f))
        }
    }
}
