/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

let SCHEME_HTTP_TAG: String = "http"
let SCHEME_HTTPS_TAG: String = "https"
let SCHEME_FILE_TAG: String = "file"

public interface IDataSource {
  func data(): Any

  func release(): Unit
}

public abstract class BaseDanmakuParser {
    protected var mDataSource: Option<IDataSource> = None
    protected var mTimer: Option<DanmakuTimer> = None
    protected var mDispWidth: Float64 = 0.0
    protected var mDispHeight: Float64 = 0.0
    protected var mDispDensity: Float64 = 0.0
    protected var mScaledDensity: Float64 = 0.0
    private var mDanmakus: Option<IDanmakus> = None
    protected var mDisp: Option<IDisplayer> = None
    protected var mContext: Option<DanmakuContext> = None
    protected var mListener: Option<(BaseDanmaku) -> Unit> = None
    public open func setDisplayer(disp: IDisplayer): BaseDanmakuParser {
        this.mDisp = disp
        this.mDispWidth = disp.getWidth()
        this.mDispHeight = disp.getHeight()
        this.mDispDensity = disp.getDensity()
        this.mScaledDensity = disp.getScaledDensity()
        this.mContext?.mDanmakuFactory.updateViewportState(this.mDispWidth, this.mDispHeight, this.getViewportSizeFactor())
        this.mContext?.mDanmakuFactory.updateMaxDanmakuDuration()
        return this
    }

    public static func getDefaultJsonDanmakuParser(): BaseDanmakuParser {
        DefaultJsonDanmakuParser()
    }

  public func getDisplayer(): ?IDisplayer {
    return this.mDisp
  }

  public func setListener(listener: (BaseDanmaku) -> Unit): BaseDanmakuParser {
    this.mListener = listener
    return this
  }

  /**
   * decide the speed of scroll-danmakus
   * @return
   */
  protected func getViewportSizeFactor(): Float64 {
    return 1.0 / (this.mDispDensity * 0.8)
  }

  public func load(source: IDataSource): BaseDanmakuParser {
    this.mDataSource = source
    return this
  }

  public func setTimer(timer: DanmakuTimer): BaseDanmakuParser {
    this.mTimer = timer
    return this
  }

  public func getTimer(): ?DanmakuTimer {
    return this.mTimer
  }

  public func getDanmakus(): IDanmakus {
    if (let Some(v) <- this.mDanmakus) {
      return v
    }
    this.mContext?.mDanmakuFactory.resetDurationsData()
    let m = this.parse()
    this.mDanmakus = m
    this.releaseDataSource()
    this.mContext?.mDanmakuFactory.updateMaxDanmakuDuration()
    return m
  }

  protected func releaseDataSource(): Unit {
    this.mDataSource?.release()
    this.mDataSource = None
  }

  protected func parse(): IDanmakus

  public func release(): Unit {
    this.releaseDataSource()
  }

  public func setConfig(config: DanmakuContext): BaseDanmakuParser {
    this.mContext = config
    return this
  }
}

