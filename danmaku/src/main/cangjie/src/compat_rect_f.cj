/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class RectF {
    public var left: Float64
    public var top: Float64
    public var right: Float64
    public var bottom: Float64

    public init() {
        left = 0.0
        top = 0.0
        right = 0.0
        bottom = 0.0
    }

    public func setEmpty(): Unit {
        left = 0.0
        top = 0.0
        right = 0.0
        bottom = 0.0
    }
    public func set(left: Float64, top: Float64, right: Float64, bottom: Float64): Unit {
        this.left = left
        this.top = top
        this.right = right
        this.bottom = bottom
    }

    public func intersect(left: Float64, top: Float64, right: Float64, bottom: Float64): Bool {
        if (left < right && left < right && top < bottom && top < bottom) {
            if (left < left) {
                this.left = left
            }
            if (top < top) {
                this.top = top
            }
            if (right > right) {
                this.right = right
            }
            if (bottom > bottom) {
                this.bottom = bottom
            }
            return true
        }
        return false
    }
    public func width(): Float64 {
        return right - left
    }

    public func height(): Float64 {
        return bottom - top
    }
}
