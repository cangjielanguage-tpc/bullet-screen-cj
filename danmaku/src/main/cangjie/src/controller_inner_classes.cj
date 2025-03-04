/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class DanmakuCanvas2D {
    private let context: CanvasRenderingContext2D
    var height_: Float64 = 0.0
    var width_: Float64 = 0.0

    let lock = ReentrantMutex()
    func getContext(): CanvasRenderingContext2D {
        context
    }
    public prop height: Float64 {
        get() {
            height_
        }
    }

    public prop width: Float64 {
        get() {
            width_
        }
    }

    public init(ca: CanvasRenderingContext2D) {
        this.context = ca
    }

    public func setWidthHeight(width: Float64, height: Float64) {
        this.width_ = width
        this.height_ = height
    }

    public func fillStyle(color: UInt32): Unit {
        this.context.fillStyle(color)
    }

    public func fillText(text: String, x: Float64, y: Float64): Unit {
        this.context.fillText(text, x, y)
    }
    public func fillText(text: String, x: Int64, y: Int64): Unit {
        this.context.fillText(text, x, y)
    }
    public func clearRect(x: Float64, y: Float64, width: Float64, height: Float64): Unit {
        this.context.clearRect(x, y, width, height)
    }
    public func clearRect(x: Int64, y: Int64, width: Int64, height: Int64): Unit {
        this.context.clearRect(x, y, width, height)
    }

    public func restore(): Unit {
        this.context.restore()
    }

    public func drawImage(image: PixelMap, dx: Float64, dy: Float64, dWidth: Float64, dHeight: Float64): Unit {
        this.context.drawImage(image, dx, dy, dWidth, dHeight)
    }
    public func drawImage(image: ImageBitmap, dx: Float64, dy: Float64, dWidth: Float64, dHeight: Float64): Unit {
        this.context.drawImage(image, dx, dy, dWidth, dHeight)
    }

    public func fillRect(x: Float64, y: Float64, width: Float64, height: Float64): Unit {
        this.context.fillRect(x, y, width, height)
    }
    public func translate(x: Float64, y: Float64): Unit {
        this.context.translate(x, y)
    }
    public func save(): Unit {
        this.context.save()
    }

    public func strokeRect(x: Float64, y: Float64, width: Float64, height: Float64): Unit {
        this.context.strokeRect(x, y, width, height)
    }

    public func stroke(path2D: Path2D): Unit {
        this.context.stroke(path2D)
    }
    public func measureText(text: String): TextMetrics {
        this.context.measureText(text)
    }
    public func rotate(angle: Float64): Unit {
        this.context.rotate(angle)
    }
    public func strokeText(text: String, x: Float64, y: Float64): Unit{
        this.context.strokeText(text,x,y)
    }

}

public class ConfigChangedCallback <: Equatable<ConfigChangedCallback> {
    static let rand = Random()
    var fv: (DanmakuContext, DanmakuConfigTag, Array<Any>) -> Bool
    let ID: Int64
    init(f: (DanmakuContext, DanmakuConfigTag, Array<Any>) -> Bool) {
        this.fv = f
        this.ID = rand.nextInt64()
    }

    func onDanmakuConfigChanged(config: DanmakuContext, tag: DanmakuConfigTag, value: Array<Any>): Bool {
        return fv(config, tag, value)
    }

    public operator func ==(that: ConfigChangedCallback): Bool {
        return this.ID == that.ID || refEq(this, that)
    }

    public operator func !=(that: ConfigChangedCallback): Bool {
        return !(this == that)
    }
}

class Task <: TaskListener {
    private var that: DrawHandler
    private var runnable: () -> Unit
    init(that: DrawHandler, runnable: () -> Unit) {
        this.that = that
        this.runnable = runnable
    }
    public func ready(): Unit {
        this.that.initRenderingConfigs();
        this.runnable();
    }

    public func onDanmakuAdd(danmaku: BaseDanmaku): Unit {
        if (danmaku.isTimeOut()) {
            return;
        }
        let delay: Int64 = danmaku.getActualTime() - this.that.getCurrentTime();
        if (delay < this.that.mContext().mDanmakuFactory.MAX_DANMAKU_DURATION && (this.that.mInWaitingState || this
            .that
            .mRenderingState
            .nothingRendered)) {
            this.that.notifyRendering();
        } else if (delay > 0 && delay <= this.that.mContext().mDanmakuFactory.MAX_DANMAKU_DURATION) {
            this.that.sendEmptyMessageDelayed(NOTIFY_RENDERING, delay);
        }
    }

    public func onDanmakuShown(danmaku: BaseDanmaku): Unit {
        this.that.mCallback?.danmakuShown(danmaku)
    }

    public func onDanmakusDrawingFinished(): Unit {
        this.that.mCallback?.drawingFinished()
    }

    public func onDanmakuConfigChanged(): Unit {
        this.that.redrawIfNeeded();
    }
}
