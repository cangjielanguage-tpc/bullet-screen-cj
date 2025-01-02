/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public let DANMAKU_STYLE_DEFAULT: Int64 = -1 // 自动
public let DANMAKU_STYLE_NONE: Int64 = 0 // 无
public let DANMAKU_STYLE_SHADOW: Int64 = 1 // 阴影
public let DANMAKU_STYLE_STROKEN: Int64 = 2 // 描边
public let DANMAKU_STYLE_PROJECTION: Int64 = 3 // 投影

public interface IDisplayer {
    func getWidth(): Float64

    func getHeight(): Float64

    func getDensity(): Float64

    func getDensityDpi(): Int64

    func draw(danmaku: BaseDanmaku): Int64

    func recycle(danmaku: BaseDanmaku): Unit

    func getScaledDensity(): Float64

    func getSlopPixel(): Int64

    func prepare(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit

    func measure(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit

    func getStrokeWidth(): Float64

    func resetSlopPixel(factor: Float64): Unit

    func setDensities(density: Float64, densityDpi: Int64, scaledDensity: Float64): Unit

    func setSize(width: Float64, height: Float64): Unit

    func setDanmakuStyle(style: Int64, data: Array<Float64>): Unit

    func setMargin(m: Int64): Unit

    func getMargin(): Int64

    func setAllMarginTop(m: Int64): Unit

    func getAllMarginTop(): Int64
}
