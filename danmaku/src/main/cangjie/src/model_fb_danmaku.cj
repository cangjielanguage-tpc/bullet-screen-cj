/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public class FBDanmaku <: FTDanmaku {
    public init(duration: DanmakuDuration) {
        super(duration)
    }

    public override func getType(): Int64 {
        return BaseDanmaku.TYPE_FIX_BOTTOM
    }
}
