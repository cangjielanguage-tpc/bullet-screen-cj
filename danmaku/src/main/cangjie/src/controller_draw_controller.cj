/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku


/**
export interface IDanmakuViewController {

  isViewReady(): boolean;

  getViewWidth(): number;

  getViewHeight(): number;

  drawDanmakus(): number;

  clear(): void;

}

*/
/**
 * For internal control. DO NOT ACCESS this interface.
 */
sealed interface IDanmakuViewController {

    public func isViewReady(): Bool

    public func getViewWidth(): Int64

    public func getViewHeight(): Int64

//    public Context getContext();

    public func drawDanmakus(): Int64

    public func clear(): Unit

//    public func isHardwareAccelerated(): Bool

    public func isDanmakuDrawingCacheEnabled(): Bool

}
