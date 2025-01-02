/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class DanmakuCanvas2D {
    let context: CanvasRenderingContext2D
    var height_: Float64 = 0.0
    var width_: Float64 = 0.0

    public prop height: Float64{
        get() {
            height_
        }
    }

    public prop width: Float64 {
        get() {
            width_
        }
    }

    public init (ca: CanvasRenderingContext2D) {
        this.context = ca
    }

    public func setWidthHeight(width: Float64, height: Float64) {
        this.width_ = width
        this.height_ = height
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
  private var that:DrawHandler;
  private var runnable:() -> Unit;
  init(that :DrawHandler,  runnable:() -> Unit) {
    this.that = that
    this.runnable = runnable
  }
  public func ready(): Unit {
    this.that.initRenderingConfigs();
    this.runnable();
  }

  public func onDanmakuAdd(danmaku: BaseDanmaku): Unit{
    if (danmaku.isTimeOut()) {
      return;
    }
    let delay: Int64 = danmaku.getActualTime() - this.that.getCurrentTime();
    if (delay < this.that.mContext().mDanmakuFactory.MAX_DANMAKU_DURATION && (this.that.mInWaitingState || this.that.mRenderingState.nothingRendered)) {
      this.that.notifyRendering();
    } else if (delay > 0 && delay <= this.that.mContext().mDanmakuFactory.MAX_DANMAKU_DURATION) {
      this.that.sendEmptyMessageDelayed(NOTIFY_RENDERING, delay);
    }
  }

  public func onDanmakuShown(danmaku: BaseDanmaku): Unit {
      this.that.mCallback?.danmakuShown(danmaku);
  }

  public func onDanmakusDrawingFinished(): Unit {
    // if (this.that.mCallback != null) {
      this.that.mCallback?.drawingFinished();
    // }
  }

  public func onDanmakuConfigChanged(): Unit {
    this.that.redrawIfNeeded();
  }
}