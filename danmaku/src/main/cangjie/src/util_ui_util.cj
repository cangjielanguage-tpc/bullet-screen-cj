/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */
package danmaku

public class SystemClock {
    public static func uptimeMillis(): Int64 {
        return DateTime.now().second * 1000
    }
}

public func measureTextHeight(paint: DanmakuPaint): Float64 {
    applyPaintToCanvas(paint, paint.getContext())
    if (let Some(context) <- paint.getContext()) {
        return context.measureText("M").width * 1.2
    }
    return paint.getTextSize()
}

public func measureTextWidth(text: String, paint: DanmakuPaint): Float64 {
    applyPaintToCanvas(paint, paint.getContext())
    if (let Some(v) <- paint.getContext()) {
        return v.measureText(text).width
    } else {
        return 1.0
    }
}

public func applyPaintToCanvas(paint: DanmakuPaint, context: ?CanvasRenderingContext2D): Unit {
    if (let Some(v) <- context) {
        v.font(size: Length(paint.getTextSize(), unitType: LengthType.px), family: paint.getTypeface())
        v.lineWidth(px2vp(Length(paint.getStrokeWidth(), unitType: LengthType.px))().value)
        v.shadowBlur(px2vp(Length(paint.getRadius(), unitType: LengthType.px))().value)
        v.shadowOffsetX(px2vp(Length(paint.getDx(), unitType: LengthType.px))().value)
        v.shadowOffsetY(px2vp(Length(paint.getDy(), unitType: LengthType.px))().value)
        v.shadowColor(paint.getShadowColor())
        v.shadowBlur(paint.getRadius())
        v.fillStyle(colorNumber2String(paint.getColor(), paint.getAlpha()))
        v.strokeStyle(colorNumber2String(paint.getColor(), paint.getAlpha()))
    }
}

func colorNumber2String(color: UInt32, alpha: Int64): UInt32 {
    (color & 0xffffff) << 8 | UInt32(alpha & 0xff)
}
