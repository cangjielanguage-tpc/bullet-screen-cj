/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package danmaku

public class SystemClock {
    public static func uptimeMillis(): Int64 {
        return DateTime.now().toUnixTimeStamp().toMilliseconds()
    }
}

public func measureTextHeight(paint: DanmakuPaint): Float64 {
    applyPaintToCanvas(paint, paint.getContext())
    if (let Some(context) <- paint.getContext()) {
        return (context.context.measureText("M").width * 1.2) / pxTovp
    }
    return paint.getTextSize()
}

public func measureTextWidth(text: String, paint: DanmakuPaint): Float64 {
    applyPaintToCanvas(paint, paint.getContext())
    if (let Some(v) <- paint.getContext()) {
        return v.context.measureText(text).width
    } else {
        return 1.0
    }
}

public func applyPaintToCanvas(paint: DanmakuPaint, context: ?DanmakuCanvas2D): Unit {
    if (let Some(v) <- context) {
        v.context.font(size: Length(paint.getTextSize(), unitType: LengthType.px), family: paint.getTypeface())
        v.context.lineWidth(paint.getStrokeWidth() / pxTovp)
        v.context.shadowBlur(paint.getRadius() / pxTovp)
        v.context.shadowOffsetX(paint.getDx() / pxTovp)
        v.context.shadowOffsetY(paint.getDy() / pxTovp)
        v.context.shadowColor(paint.getShadowColor())
        v.context.shadowBlur(paint.getRadius())
        v.context.fillStyle(colorNumber2String(paint.getColor(), paint.getAlpha()))
        v.context.strokeStyle(colorNumber2String(paint.getColor(), paint.getAlpha()))
    }
}

func colorNumber2String(color: UInt32, alpha: Int64): UInt32 {
    (color & 0xffffff) << 8 | UInt32(alpha & 0xff)
}
