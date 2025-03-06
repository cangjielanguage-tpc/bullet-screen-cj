/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package danmaku

public class SystemClock {
    public static func uptimeMillis(): Int64 {
        return SystemDateTime.getRealTime()
    }
}

public func measureTextHeight(paint: DanmakuPaint): Float64 {
    applyPaintToCanvas(paint, paint.getContext())
    if (let Some(context) <- paint.getContext()) {
        return (context.measureText("M").width * 1.2) / pxTovp
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

public func applyPaintToCanvas(paint: DanmakuPaint, context: ?DanmakuCanvas2D): Unit {
    if (let Some(v) <- context) {
        synchronized (v.lock) {
            v.getContext().font(size: Length(paint.getTextSize(), unitType: LengthType.px),weight: if (paint.getFakeBoldText()){FontWeight.Bolder} else {FontWeight.Normal}, family: paint.getTypeface())
            v.getContext().lineWidth(paint.getStrokeWidth() / pxTovp)
            v.getContext().shadowBlur(paint.getRadius() / pxTovp)
            v.getContext().shadowOffsetX(paint.getDx() / pxTovp)
            v.getContext().shadowOffsetY(paint.getDy() / pxTovp)
            v.getContext().shadowColor(paint.getShadowColor())
            v.getContext().shadowBlur(paint.getRadius())
            v.getContext().fillStyle(colorNumber2String(paint.getColor(), paint.getAlpha()))
            v.getContext().strokeStyle(colorNumber2String(paint.getColor(), paint.getAlpha()))
        }
    }
}

func colorNumber2String(color: UInt32, alpha: Int64): UInt32 {
    (color & 0xffffff) | (UInt32(alpha & 0xff) << 24)// 0xFF_FF_FF_FF  0xalpha_R_G_B
}
