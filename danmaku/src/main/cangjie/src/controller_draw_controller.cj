/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

/**
 * For internal control. DO NOT ACCESS this interface.
 */
sealed interface IDanmakuViewController {

    public func isViewReady(): Bool

    public func getViewWidth(): Float64

    public func getViewHeight(): Float64

    public func drawDanmakus(): Int64

    public func clear(): Unit

    public func isDanmakuDrawingCacheEnabled(): Bool

}
