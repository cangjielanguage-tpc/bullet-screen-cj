/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public abstract class AbsDisplayer<T, F> <: IDisplayer {
    public func getExtraData(): T

    public func setExtraData(data: T): Unit

    public func drawDanmaku(danmaku: BaseDanmaku, canvas: T, left: Float64, top: Float64, fromWorkerThread: Bool): Unit

    public func clearTextHeightCache(): Unit

    public func setTypeFace(font: F): Unit

    public func setFakeBoldText(bold: Bool): Unit

    public func setTransparency(newTransparency: Int64): Unit

    public func setScaleTextSizeFactor(factor: Float64): Unit

    public func setCacheStuffer(cacheStuffer: ?BaseCacheStuffer): Unit

    public func getCacheStuffer(): ?BaseCacheStuffer

    public func getWidth(): Float64

    public func getHeight(): Float64

    public func getDensity(): Float64

    public func getDensityDpi(): Int64

    public func draw(danmaku: BaseDanmaku): Int64

    public func recycle(danmaku: BaseDanmaku): Unit

    public func getScaledDensity(): Float64

    public func getSlopPixel(): Int64

    public func prepare(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit

    public func measure(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit

    public func getStrokeWidth(): Float64

    public func resetSlopPixel(factor: Float64): Unit

    public func setDensities(density: Float64, densityDpi: Int64, scaledDensity: Float64): Unit

    public func setSize(width: Float64, height: Float64): Unit

    public func setDanmakuStyle(style: Int64, data: Array<Float64>): Unit

    public func setMargin(m: Int64): Unit

    public func getMargin(): Int64

    public func setAllMarginTop(m: Int64): Unit

    public func getAllMarginTop(): Int64
}
