/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public class DisplayerConfig {
    private var sLastScaleTextSize: Float64 = 0.0
    private var sCachedScaleSize: HashMap<Float64, Float64> = HashMap<Float64, Float64>()
    public var PAINT: DanmakuPaint
    public var PAINT_DUPLICATE: DanmakuPaint
    public var ALPHA_PAINT: DanmakuPaint
    public var UNDERLINE_PAINT: DanmakuPaint
    public var BORDER_PAINT: DanmakuPaint

    /**
     * 下划线高度
     */
    public let UNDERLINE_HEIGHT: Float64 = 4.0

    /**
     * 边框厚度
     */
    public let BORDER_WIDTH: Float64 = 4.0

    /**
     * 阴影半径
     */
    private var SHADOW_RADIUS: Float64 = 4.0

    /**
     * 描边宽度
     */
    private var STROKE_WIDTH: Float64 = 3.5

    /**
     * 投影参数
     */
    public var sProjectionOffsetX: Float64 = 1.0
    public var sProjectionOffsetY: Float64 = 1.0
    private var sProjectionAlpha: Int64 = 0xCC

    /**
     * 开启阴影，可动态改变
     */
    public var CONFIG_HAS_SHADOW: Bool = false
    private var HAS_SHADOW: Bool = CONFIG_HAS_SHADOW

    /**
     * 开启描边，可动态改变
     */
    public var CONFIG_HAS_STROKE: Bool = true
    public var HAS_STROKE: Bool = CONFIG_HAS_STROKE

    /**
     * 开启投影，可动态改变
     */
    public var CONFIG_HAS_PROJECTION: Bool = false
    public var HAS_PROJECTION: Bool = CONFIG_HAS_PROJECTION

    /**
     * 开启抗锯齿，可动态改变
     */
    public var CONFIG_ANTI_ALIAS: Bool = true
    private var ANTI_ALIAS: Bool = CONFIG_ANTI_ALIAS
    private var isTranslucent: Bool = false
    private var transparency: Int64 = AlphaValue.MAX
    private var scaleTextSize: Float64 = 1.0
    private var isTextScaled: Bool = false
    public var margin: Int64 = 0
    public var allMarginTop: Int64 = 0

    public init() {
        PAINT = DanmakuPaint(Option<CanvasRenderingContext2D>.None)
        PAINT.setStrokeWidth(STROKE_WIDTH)
        PAINT_DUPLICATE = DanmakuPaint(Option<CanvasRenderingContext2D>.None, paint: PAINT)
        ALPHA_PAINT = DanmakuPaint(Option<CanvasRenderingContext2D>.None)
        UNDERLINE_PAINT = DanmakuPaint(Option<CanvasRenderingContext2D>.None)
        UNDERLINE_PAINT.setStrokeWidth(UNDERLINE_HEIGHT)
        UNDERLINE_PAINT.setStyle(Style.STROKE)
        BORDER_PAINT = DanmakuPaint(Option<CanvasRenderingContext2D>.None)
        BORDER_PAINT.setStyle(Style.STROKE)
        BORDER_PAINT.setStrokeWidth(BORDER_WIDTH)
    }

    public func setTypeface(typeface: String): Unit {
        PAINT.setTypeface(typeface)
    }

    public func setShadowRadius(shadowRadius: Float64): Unit {
        SHADOW_RADIUS = shadowRadius
    }

    public func setStrokeWidth(s: Float64): Unit {
        PAINT.setStrokeWidth(s)
        STROKE_WIDTH = s
    }

    public func setProjectionConfig(offsetX: Float64, offsetY: Float64, alpha: Int64): Unit {
        if (sProjectionOffsetX != offsetX || sProjectionOffsetY != offsetY || sProjectionAlpha != alpha) {
            sProjectionOffsetX = if (offsetX > 1.0) {
                offsetX
            } else {
                1.0
            }
            sProjectionOffsetY = if (offsetY > 1.0) {
                offsetY
            } else {
                1.0
            }
            sProjectionAlpha = if (alpha < 0) {
                0
            } else {
                if (alpha > 255) {
                    255
                } else {
                    alpha
                }
            }
        }
    }

    public func setFakeBoldText(fakeBoldText: Bool): Unit {
        PAINT.setFakeBoldText(fakeBoldText)
    }

    public func setTransparency(newTransparency: Int64): Unit {
        isTranslucent = (newTransparency != AlphaValue.MAX)
        transparency = newTransparency
    }

    public func setScaleTextSizeFactor(factor: Float64): Unit {
        isTextScaled = (factor != 1.0)
        scaleTextSize = factor
    }

    private func applyTextScaleConfig(danmaku: BaseDanmaku, DanmakuPaint: DanmakuPaint): Unit {
        if (!isTextScaled) {
            return
        }
        var size: ?Float64 = sCachedScaleSize.get(danmaku.textSize)
        if (size.isNone() || sLastScaleTextSize != scaleTextSize) {
            sLastScaleTextSize = scaleTextSize
            size = danmaku.textSize * scaleTextSize
            sCachedScaleSize.put(danmaku.textSize, size())
        }
        DanmakuPaint.setTextSize(size())
    }

    public func hasStroke(danmaku: BaseDanmaku): Bool {
        return (HAS_STROKE || HAS_PROJECTION) && STROKE_WIDTH > 0.0 && danmaku.textShadowColor != 0
    }

    public func getBorderPaint(danmaku: BaseDanmaku): DanmakuPaint {
        BORDER_PAINT.setColor(danmaku.borderColor)
        return BORDER_PAINT
    }

    public func getUnderlinePaint(danmaku: BaseDanmaku): DanmakuPaint {
        UNDERLINE_PAINT.setColor(danmaku.underlineColor)
        return UNDERLINE_PAINT
    }

    public func getPaint(danmaku: BaseDanmaku, fromWorkerThread: Bool): DanmakuPaint {
        var paint: DanmakuPaint
        if (fromWorkerThread) {
            paint = PAINT
        } else {
            paint = PAINT_DUPLICATE
            paint.set(PAINT)
        }
        paint.setTextSize(danmaku.textSize)
        applyTextScaleConfig(danmaku, paint)

        //ignore the transparent textShadowColor
        if (!HAS_SHADOW || SHADOW_RADIUS <= 0.0 || danmaku.textShadowColor == 0) {
            paint.clearShadowLayer()
        } else {
            paint.setShadowLayer(SHADOW_RADIUS, 0.0, 0.0, danmaku.textShadowColor)
        }
        return paint
    }

    public func applyPaintConfig(danmaku: BaseDanmaku, paint: DanmakuPaint, stroke: Bool): Unit {
        if (isTranslucent) {
            if (stroke) {
                if (HAS_PROJECTION) {
                    paint.setStyle(Style.FILL)
                } else {
                    paint.setStyle(Style.FILL_AND_STROKE)
                }
                paint.setColor(danmaku.textShadowColor & 0x00FFFFFF)
                let alpha: Int64 = if (HAS_PROJECTION) {
                    sProjectionAlpha * (transparency / AlphaValue.MAX)
                } else {
                    transparency
                }
                paint.setAlpha(alpha)
            } else {
                paint.setStyle(Style.FILL)
                paint.setColor(danmaku.textColor & 0x00FFFFFF)
                paint.setAlpha(transparency)
            }
        } else {
            if (stroke) {
                if (HAS_PROJECTION) {
                    paint.setStyle(Style.FILL)
                } else {
                    paint.setStyle(Style.FILL_AND_STROKE)
                }
                paint.setColor(danmaku.textShadowColor & 0x00FFFFFF)
                let alpha: Int64 = if (HAS_PROJECTION) {
                    sProjectionAlpha
                } else {
                    AlphaValue.MAX
                }
                paint.setAlpha(alpha)
            } else {
                paint.setStyle(Style.FILL)
                paint.setColor(danmaku.textColor & 0x00FFFFFF)
                paint.setAlpha(AlphaValue.MAX)
            }
        }

        if (danmaku.getType() == BaseDanmaku.TYPE_SPECIAL) {
            paint.setAlpha(danmaku.getAlpha())
        }
    }

    public func clearTextHeightCache(): Unit {
        sCachedScaleSize.clear()
    }

    public func getStrokeWidth(): Float64 {
        if (HAS_SHADOW && HAS_STROKE) {
            return max(SHADOW_RADIUS, STROKE_WIDTH)
        }
        if (HAS_SHADOW) {
            return SHADOW_RADIUS
        }
        if (HAS_STROKE) {
            return STROKE_WIDTH
        }
        return 0.0
    }

    public func definePaintParams(fromWorkerThread: Bool): Unit {
        HAS_STROKE = CONFIG_HAS_STROKE
        HAS_SHADOW = CONFIG_HAS_SHADOW
        HAS_PROJECTION = CONFIG_HAS_PROJECTION
        ANTI_ALIAS = CONFIG_ANTI_ALIAS
    }
}

public class OhcjDisplayer <: AbsDisplayer<CanvasRenderingContext2D, String> {
    private var mDisplayConfig: DisplayerConfig = DisplayerConfig()
    private var sStuffer: ?BaseCacheStuffer = None

    public init() {
        super()
    }

    public func setTypeFace(font: String): Unit {
        mDisplayConfig.setTypeface(font)
    }

    public func setShadowRadius(s: Float64): Unit {
        mDisplayConfig.setShadowRadius(s)
    }

    public func setPaintStorkeWidth(s: Float64): Unit {
        mDisplayConfig.setStrokeWidth(s)
    }

    public func setProjectionConfig(offsetX: Float64, offsetY: Float64, alpha: Int64): Unit {
        mDisplayConfig.setProjectionConfig(offsetX, offsetY, alpha)
    }

    public func setFakeBoldText(fakeBoldText: Bool): Unit {
        mDisplayConfig.setFakeBoldText(fakeBoldText)
    }

    public override func setTransparency(newTransparency: Int64): Unit {
        mDisplayConfig.setTransparency(newTransparency)
    }

    public override func setScaleTextSizeFactor(factor: Float64): Unit {
        mDisplayConfig.setScaleTextSizeFactor(factor)
    }

    public override func setCacheStuffer(cacheStuffer: ?BaseCacheStuffer): Unit {
        if (cacheStuffer != sStuffer) {
            sStuffer = cacheStuffer
        }
    }

    public override func getCacheStuffer(): ?BaseCacheStuffer {
        return sStuffer
    }

    public override func setMargin(m: Int64): Unit {
        mDisplayConfig.margin = m
    }

    public override func getMargin(): Int64 {
        return mDisplayConfig.margin
    }

    public override func setAllMarginTop(m: Int64): Unit {
        mDisplayConfig.allMarginTop = m
    }

    public override func getAllMarginTop(): Int64 {
        return mDisplayConfig.allMarginTop
    }

    public var canvas: ?CanvasRenderingContext2D = None
    private var width: Float64 = 0.0
    private var height: Float64 = 0.0
    private var locationZ: Float64 = 0.0
    private var density: Float64 = 1.0
    private var densityDpi: Int64 = 160
    private var scaledDensity: Float64 = 1.0
    private var mSlopPixel: Int64 = 0

    private func update(c: ?CanvasRenderingContext2D): Unit {
        canvas = c
        if (let Some(v) <- c) {
            //      width = v.width TODO..
            //      height = v.height TODO..
            mDisplayConfig.PAINT.setContext(c)
            mDisplayConfig.PAINT_DUPLICATE.setContext(c)
            mDisplayConfig.BORDER_PAINT.setContext(c)
            mDisplayConfig.ALPHA_PAINT.setContext(c)
            mDisplayConfig.UNDERLINE_PAINT.setContext(c)
        }
    }

    public override func getWidth(): Float64 {
        return width
    }

    public override func getHeight(): Float64 {
        return height
    }

    public override func getDensity(): Float64 {
        return density
    }

    public override func getDensityDpi(): Int64 {
        return densityDpi
    }

    public override func draw(danmaku: BaseDanmaku): Int64 {
        let top: Float64 = danmaku.getTop()
        let left: Float64 = danmaku.getLeft()
        if (let Some(canvas) <- canvas) {
            var alphaPaint: ?DanmakuPaint = None
            var needRestore: Bool = false
            if (danmaku.getType() == BaseDanmaku.TYPE_SPECIAL) {
                if (danmaku.getAlpha() == AlphaValue.TRANSPARENT) {
                    return NOTHING_RENDERING
                }
                if (danmaku.rotationZ != 0.0 || danmaku.rotationY != 0.0) {
                    saveCanvas(danmaku, canvas, left, top)
                    needRestore = true
                }
                let alpha: Int64 = danmaku.getAlpha()
                if (alpha != AlphaValue.MAX) {
                    alphaPaint = mDisplayConfig.ALPHA_PAINT
                    alphaPaint().setAlpha(danmaku.getAlpha())
                }
            }

            // skip drawing when danmaku is transparent
            if (alphaPaint.isSome() && alphaPaint().getAlpha() == AlphaValue.TRANSPARENT) {
                return NOTHING_RENDERING
            }

            // drawing cache
            var result: Int64 = NOTHING_RENDERING
            if (let Some(v) <- alphaPaint) {
                mDisplayConfig.PAINT.setAlpha(v.getAlpha())
                mDisplayConfig.PAINT_DUPLICATE.setAlpha(v.getAlpha())
            } else {
                resetPaintAlpha(mDisplayConfig.PAINT)
            }
            drawDanmaku(danmaku, canvas, left, top, false)
            result = TEXT_RENDERING

            if (needRestore) {
                restoreCanvas(canvas)
            }

            return result
        }

        return NOTHING_RENDERING
    }

    public override func recycle(danmaku: BaseDanmaku): Unit {
        if (let Some(v) <- sStuffer) {
            v.releaseResource(danmaku)
        }
    }

    private func resetPaintAlpha(paint: DanmakuPaint): Unit {
        if (paint.getAlpha() != AlphaValue.MAX) {
            paint.setAlpha(AlphaValue.MAX)
        }
    }

    private func restoreCanvas(canvas: CanvasRenderingContext2D): Unit {
        canvas.restore()
    }

    private func saveCanvas(danmaku: BaseDanmaku, canvas: CanvasRenderingContext2D, left: Float64, top: Float64): Int64 {
        return 0
    }

    public override func drawDanmaku(danmaku: BaseDanmaku, canvas: CanvasRenderingContext2D, left: Float64,
        top: Float64, fromWorkerThread: Bool): Unit {
        if (let Some(v) <- sStuffer) {
            v.drawDanmaku(danmaku, canvas, left, top, fromWorkerThread, mDisplayConfig)
        }
    }

    private func getPaint(danmaku: BaseDanmaku, fromWorkerThread: Bool): DanmakuPaint {
        return mDisplayConfig.getPaint(danmaku, fromWorkerThread)
    }

    public override func prepare(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit {
        if (let Some(v) <- sStuffer) {
            v.prepare(danmaku, fromWorkerThread)
        }
    }

    public override func measure(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit {
        let paint: DanmakuPaint = getPaint(danmaku, fromWorkerThread)
        if (mDisplayConfig.HAS_STROKE) {
            mDisplayConfig.applyPaintConfig(danmaku, paint, true)
        }
        calcPaintWH(danmaku, paint, fromWorkerThread)
        if (mDisplayConfig.HAS_STROKE) {
            mDisplayConfig.applyPaintConfig(danmaku, paint, false)
        }
    }

    private func calcPaintWH(danmaku: BaseDanmaku, DanmakuPaint: DanmakuPaint, fromWorkerThread: Bool): Unit {
        sStuffer().measure(danmaku, DanmakuPaint, fromWorkerThread)
        setDanmakuPaintWidthAndHeight(danmaku, danmaku.paintWidth, danmaku.paintHeight)
    }

    private func setDanmakuPaintWidthAndHeight(danmaku: BaseDanmaku, w: Float64, h: Float64): Unit {
        var pw: Float64 = w + 2.0 * danmaku.padding
        var ph: Float64 = h + 2.0 * danmaku.padding
        if (danmaku.borderColor != 0) {
            pw += 2.0 * mDisplayConfig.BORDER_WIDTH
            ph += 2.0 * mDisplayConfig.BORDER_WIDTH
        }
        danmaku.paintWidth = pw + getStrokeWidth()
        danmaku.paintHeight = ph
    }

    public override func clearTextHeightCache(): Unit {
        sStuffer().clearCaches()
        mDisplayConfig.clearTextHeightCache()
    }

    public override func getScaledDensity(): Float64 {
        return scaledDensity
    }

    public override func resetSlopPixel(factor: Float64): Unit {
        let d: Float64 = max(factor, getWidth() / Float64(DanmakuFactory.BILI_PLAYER_WIDTH)) //correct for low density and high resolution
        let slop: Float64 = d * Float64(DanmakuFactory.DANMAKU_MEDIUM_TEXTSIZE)
        mSlopPixel = Int64(slop)
        if (factor > 1.0) {
            mSlopPixel = Int64(slop * factor)
        }
    }

    public override func getSlopPixel(): Int64 {
        return mSlopPixel
    }

    public override func setDensities(density: Float64, densityDpi: Int64, scaledDensity: Float64): Unit {
        this.density = density
        this.densityDpi = densityDpi
        this.scaledDensity = scaledDensity
    }

    public override func setSize(width: Float64, height: Float64): Unit {
        this.width = width
        this.height = height
        this.locationZ = width / 2.0 / tan((Float64.PI / 180.0) * (55.0 / 2.0))
    }

    public override func setDanmakuStyle(style: Int64, values: Array<Float64>): Unit {
        match (style) {
            case DANMAKU_STYLE_NONE =>
                mDisplayConfig.CONFIG_HAS_SHADOW = false
                mDisplayConfig.CONFIG_HAS_STROKE = false
                mDisplayConfig.CONFIG_HAS_PROJECTION = false
            case DANMAKU_STYLE_SHADOW =>
                mDisplayConfig.CONFIG_HAS_SHADOW = true
                mDisplayConfig.CONFIG_HAS_STROKE = false
                mDisplayConfig.CONFIG_HAS_PROJECTION = false
                setShadowRadius(values[0])
            case DANMAKU_STYLE_DEFAULT =>
                mDisplayConfig.CONFIG_HAS_SHADOW = false
                mDisplayConfig.CONFIG_HAS_STROKE = true
                mDisplayConfig.CONFIG_HAS_PROJECTION = false
                setPaintStorkeWidth(values[0])
            case DANMAKU_STYLE_STROKEN =>
                mDisplayConfig.CONFIG_HAS_SHADOW = false
                mDisplayConfig.CONFIG_HAS_STROKE = true
                mDisplayConfig.CONFIG_HAS_PROJECTION = false
                setPaintStorkeWidth(values[0])
            case DANMAKU_STYLE_PROJECTION =>
                mDisplayConfig.CONFIG_HAS_SHADOW = false
                mDisplayConfig.CONFIG_HAS_STROKE = false
                mDisplayConfig.CONFIG_HAS_PROJECTION = true
                setProjectionConfig(values[0], values[1], Int64(values[2]))
        }
    }

    public override func setExtraData(data: ?CanvasRenderingContext2D): Unit {
        update(data)
    }

    public override func getExtraData(): ?CanvasRenderingContext2D {
        return canvas
    }

    public override func getStrokeWidth(): Float64 {
        return mDisplayConfig.getStrokeWidth()
    }
}
