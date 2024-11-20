/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public class DanmakuPaint {
    var mContext: ?CanvasRenderingContext2D = None
    var mColor: UInt32 = 0
    var mTextSize: Float64 = 15.0
    var mAlpha: Int64 = 255
    var mLineWidth: Float64 = 1.0
    var mTypeface: String = 'sans-serif'
    var mShadowBlur: Float64 = 0.0
    var mShadowOffsetX: Float64 = 0.0
    var mShadowOffsetY: Float64 = 0.0
    var mShadowColor: UInt32 = 0xFFFFFF
    var mBold: Bool = false

    public init(mContext: ?CanvasRenderingContext2D, paint!: ?DanmakuPaint = None) {
        this.mContext = mContext
        if (let Some(v) <- paint) {
            set(v)
        }
    }

    public func set(paint: DanmakuPaint): Unit {
        if (paint.mContext.isSome()) {
            mContext = paint.getContext()
        }
        mColor = paint.getColor()
        mTextSize = paint.getTextSize()
        mAlpha = paint.getAlpha()
        mLineWidth = paint.getStrokeWidth()
        mTypeface = paint.getTypeface()
        mShadowBlur = paint.getRadius()
        mShadowOffsetX = paint.getDx()
        mShadowOffsetY = paint.getDy()
        mShadowColor = paint.getShadowColor()
        mBold = paint.getFakeBoldText()
    }

    public func setContext(mContext: ?CanvasRenderingContext2D): Unit {
        this.mContext = mContext
    }

    public func getContext(): ?CanvasRenderingContext2D {
        return mContext
    }

    public func setStrokeWidth(mLineWidth: Float64): Unit {
        this.mLineWidth = mLineWidth
    }

    public func getStrokeWidth(): Float64 {
        return mLineWidth
    }

    public func setTypeface(mTypeface: String): Unit {
        this.mTypeface = mTypeface
    }

    public func getTypeface(): String {
        return mTypeface
    }

    public func setFakeBoldText(bold: Bool): Unit {
        this.mBold = bold
    }

    public func getFakeBoldText(): Bool {
        return mBold
    }

    public func setTextSize(mTextSize: Float64): Unit {
        this.mTextSize = mTextSize
    }

    public func getTextSize(): Float64 {
        return mTextSize
    }

    public func setStyle(style: Style): Unit {}

    public func setColor(mColor: UInt32): Unit {
        this.mColor = mColor
    }

    public func getColor(): UInt32 {
        return mColor
    }

    public func setAlpha(mAlpha: Int64): Unit {
        this.mAlpha = mAlpha
    }

    public func getAlpha(): Int64 {
        return mAlpha
    }

    public func clearShadowLayer(): Unit {
        this.mShadowBlur = 0.0
    }

    public func setShadowLayer(radius: Float64, dx: Float64, dy: Float64, shadowColor: UInt32): Unit {
        mShadowBlur = radius
        mShadowOffsetX = dx
        mShadowOffsetY = dy
        mShadowColor = shadowColor
    }

    public func getRadius(): Float64 {
        return mShadowBlur
    }

    public func getDx(): Float64 {
        return mShadowOffsetX
    }

    public func getDy(): Float64 {
        return mShadowOffsetY
    }

    public func getShadowColor(): UInt32 {
        return mShadowColor
    }
}

public enum Style {
    | FILL
    | STROKE
    | FILL_AND_STROKE

    public operator func ==(that: Style): Bool {
        match ((this, that)) {
            case (FILL, FILL) => true
            case (STROKE, STROKE) => true
            case (FILL_AND_STROKE, FILL_AND_STROKE) => true
            case _ => false
        }
    }
}
