/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class Danmaku <: BaseDanmaku {
    public init(text: String) {
        super()
        DanmakuUtils.fillText(this, text)
    }

    public override func isShown(): Bool {
        return false
    }

    public override func layout(displayer: IDisplayer, x: Float64, y: Float64): Unit {}

    public override func getRectAtTime(displayer: IDisplayer, time: Int64): Array<Float64> {
        return NullArray
    }

    public override func getLeft(): Float64 {
        return 0.0
    }

    public override func getTop(): Float64 {
        return 0.0
    }

    public override func getRight(): Float64 {
        return 0.0
    }

    public override func getBottom(): Float64 {
        return 0.0
    }

    public override func getType(): Int64 {
        return 0
    }
}
