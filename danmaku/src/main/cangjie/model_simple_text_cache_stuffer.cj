/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public open class SimpleTextCacheStuffer <: BaseCacheStuffer {
    private static var sTextHeightCache: HashMap<Float64, Float64> = HashMap<Float64, Float64>()

    protected func getCacheHeight(_: BaseDanmaku, paint: DanmakuPaint): Float64 {
        let textSize: Float64 = paint.getTextSize()
        return if (let Some(textHeight) <- sTextHeightCache.get(textSize)) {
            textHeight
        } else {
            let textHeight = measureTextHeight(paint)
            sTextHeightCache.add(textSize, textHeight)
            textHeight
        }
    }

    public open override func measure(danmaku: BaseDanmaku, paint: DanmakuPaint, _: Bool): Unit {
        var w: Float64 = 0.0
        var textHeight: Float64 = 0.0
        if (let Some(v) <- danmaku.lines) {
            textHeight = getCacheHeight(danmaku, paint)
            for (tempStr in v) {
                if (tempStr.size > 0) {
                    let tr: Float64 = measureTextWidth(tempStr, paint)
                    w = max(tr, w)
                }
            }
            danmaku.paintWidth = w
            danmaku.paintHeight = Float64(v.size) * textHeight
        } else {
            if (danmaku.text == "") {
                w = 0.0
            } else {
                w = measureTextWidth(danmaku.text, paint)
                textHeight = getCacheHeight(danmaku, paint)
            }
            danmaku.paintWidth = w
            danmaku.paintHeight = textHeight
        }
    }

    protected open func drawStroke(danmaku: BaseDanmaku, lineText: String, canvas: DanmakuCanvas2D,
        left: Float64, top: Float64, paint: DanmakuPaint): Unit {
        if (lineText != "") {
            applyPaintToCanvas(paint, canvas)
            canvas.strokeText(lineText, left, top)
        } else {
            applyPaintToCanvas(paint, canvas)
            canvas.strokeText(danmaku.text, left, top)
        }
    }

    protected open func drawText(danmaku: BaseDanmaku, lineText: String, canvas: DanmakuCanvas2D,
        left: Float64, top: Float64, paint: DanmakuPaint, fromWorkerThread: Bool, _: DisplayerConfig): Unit {
        if (fromWorkerThread && danmaku is SpecialDanmaku) {
            paint.setAlpha(255)
        }
        if (lineText != "") {
            applyPaintToCanvas(paint, canvas)
            canvas.fillText(lineText, left, top)
        } else {
            applyPaintToCanvas(paint, canvas)
            canvas.fillText(danmaku.text, left, top)
        }
    }

    public open override func clearCaches(): Unit {
        sTextHeightCache.clear()
    }

    protected func drawBackground(_: BaseDanmaku, _: DanmakuCanvas2D, _: Float64, _: Float64): Unit {
    }

    public override func drawDanmaku(danmaku: BaseDanmaku, canvas: DanmakuCanvas2D, t: Float64, p: Float64,
        fromWorkerThread: Bool, displayerConfig: DisplayerConfig): Unit {
        var left = t
        var top = p
        var _left: Float64 = left
        var _top: Float64 = top
        left += danmaku.padding
        top += danmaku.padding
        if (danmaku.borderColor != 0) {
            left += displayerConfig.BORDER_WIDTH
            top += displayerConfig.BORDER_WIDTH
        }
        displayerConfig.definePaintParams(fromWorkerThread)
        let paint: DanmakuPaint = displayerConfig.getPaint(danmaku, fromWorkerThread)
        drawBackground(danmaku, canvas, _left, _top)
        let ascent = measureTextHeight(paint) * -0.9
        if (let Some(lines) <- danmaku.lines) {
            if (lines.size == 1) {
                if (displayerConfig.hasStroke(danmaku)) {
                    displayerConfig.applyPaintConfig(danmaku, paint, true)
                    var strokeLeft: Float64 = left
                    var strokeTop: Float64 = top - ascent
                    if (displayerConfig.HAS_PROJECTION) {
                        strokeLeft += displayerConfig.sProjectionOffsetX
                        strokeTop += displayerConfig.sProjectionOffsetY
                    }
                    drawStroke(danmaku, lines[0], canvas, strokeLeft, strokeTop, paint)
                }
                displayerConfig.applyPaintConfig(danmaku, paint, false)
                drawText(danmaku, lines[0], canvas, left, top - ascent, paint, fromWorkerThread, displayerConfig)
            } else {
                let textHeight: Float64 = (danmaku.paintHeight - 2.0 * danmaku.padding) / Float64(lines.size)
                for (t in 0..lines.size) {
                    if (lines[t] == "" || lines[t].size == 0) {
                        continue
                    }
                    if (displayerConfig.hasStroke(danmaku)) {
                        displayerConfig.applyPaintConfig(danmaku, paint, true)
                        var strokeLeft: Float64 = left
                        var strokeTop: Float64 = Float64(t) * textHeight + top - ascent
                        if (displayerConfig.HAS_PROJECTION) {
                            strokeLeft += displayerConfig.sProjectionOffsetX
                            strokeTop += displayerConfig.sProjectionOffsetY
                        }
                        drawStroke(danmaku, lines[t], canvas, strokeLeft, strokeTop, paint)
                    }
                    displayerConfig.applyPaintConfig(danmaku, paint, false)
                    drawText(danmaku, lines[t], canvas, left, Float64(t) * textHeight + top - ascent, paint,
                        fromWorkerThread, displayerConfig)
                }
            }
        } else {
            if (displayerConfig.hasStroke(danmaku)) {
                displayerConfig.applyPaintConfig(danmaku, paint, true)
                var strokeLeft: Float64 = left
                var strokeTop: Float64 = top - ascent
                if (displayerConfig.HAS_PROJECTION) {
                    strokeLeft += displayerConfig.sProjectionOffsetX
                    strokeTop += displayerConfig.sProjectionOffsetY
                }
                drawStroke(danmaku, "", canvas, strokeLeft, strokeTop, paint)
            }
            displayerConfig.applyPaintConfig(danmaku, paint, false)
            drawText(danmaku, "", canvas, left, top - ascent, paint, fromWorkerThread, displayerConfig)
        }
        // draw underline
        if (danmaku.underlineColor != 0) {
            let linePaint: DanmakuPaint = displayerConfig.getUnderlinePaint(danmaku)
            let bottom: Float64 = _top + danmaku.paintHeight - displayerConfig.UNDERLINE_HEIGHT
            let path: Path2D = Path2D(
                "M" + "${_left * pxTovp}" + ' ' + "${bottom * pxTovp}" + ' ' + 'L' +
                "${(_left + danmaku.paintWidth) * pxTovp}" + ' ' + "${bottom * pxTovp}")
            applyPaintToCanvas(linePaint, canvas)
            canvas.stroke(path)
        }
        //draw border
        if (danmaku.borderColor != 0) {
            let borderPaint: DanmakuPaint = displayerConfig.getBorderPaint(danmaku)
            applyPaintToCanvas(borderPaint, canvas)
            canvas.strokeRect(_left, _top, danmaku.paintWidth, danmaku.paintHeight)
        }
    }
}
