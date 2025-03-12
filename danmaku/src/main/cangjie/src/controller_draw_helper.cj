/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku


public class DrawHelper {
    public static var PAINT: ?DanmakuPaint = None
    public static var PAINT_FPS: ?DanmakuPaint = None
    public static var RECT: RectF = RectF()
    private static var USE_DRAWCOLOR_TO_CLEAR_CANVAS: Bool = true
    private static var USE_DRAWCOLOR_MODE_CLEAR: Bool = true

    public static func useDrawColorToClearCanvas(use: Bool, useClearMode: Bool): Unit {
        DrawHelper.USE_DRAWCOLOR_TO_CLEAR_CANVAS = use
        DrawHelper.USE_DRAWCOLOR_MODE_CLEAR = useClearMode
    }

    public static func drawFPS(canvas: DanmakuCanvas2D, text: String): Unit {
       if (DrawHelper.PAINT_FPS.isNone()) {
           let dp = DanmakuPaint(canvas)
           dp.setColor(0xFF0000)
           dp.setTextSize(30.0)
           DrawHelper.PAINT_FPS = dp
       }
       let top: Int64 = Int64(canvas.height) -  15
       DrawHelper.clearCanvasByPoints(canvas, 10.0, Float64(top) - 15.0, (measureTextWidth(text, DrawHelper.PAINT_FPS()) + 50.0) / pxTovp, canvas.height)

       applyPaintToCanvas(DrawHelper.PAINT_FPS(), canvas)
       canvas.fillText(text, 15, top)
    }

   public static func clearCanvas(canvas: DanmakuCanvas2D): Unit {
       DrawHelper.RECT.set(0.0, 0.0, canvas.width, canvas.height)
       DrawHelper.clearCanvasByRectF(canvas, DrawHelper.RECT)

   }

   public static func fillTransparent(canvas: DanmakuCanvas2D): Unit{
       canvas.clearRect(0.0, 0.0, canvas.width, canvas.height)
   }

   public static func clearCanvasByPoints(canvas: DanmakuCanvas2D, left: Float64, top: Float64, right: Float64, bottom: Float64): Unit {
       DrawHelper.RECT.set(left, top, right, bottom)
       DrawHelper.clearCanvasByRectF(canvas, DrawHelper.RECT)
   }

   private static func clearCanvasByRectF(canvas: DanmakuCanvas2D, rect: RectF): Unit {
       if (rect.width() <= 0.0 || rect.height() <= 0.0) {
           return
       }
       canvas.clearRect(rect.left, rect.top, rect.width(), rect.height())
   }
}


