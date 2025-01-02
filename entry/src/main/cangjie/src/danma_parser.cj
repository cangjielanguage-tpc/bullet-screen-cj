/**
 * Created on 2025/1/8
 */
package ohos_app_cangjie_entry
import ohos.resource_manager.ResourceManager
import ohos.ability.getStageContext
import ohos.hilog.*

import encoding.json.*
import std.convert.*
import std.sync.*

func printlnException(arr: Array<StackTraceElement> ): String {
    let bugs = StringBuilder()
    for (a in arr) {
        bugs.append("${a.fileName} ${a.declaringClass} ${a.lineNumber} ${a.methodName}\n")
    }
    bugs.toString()

}

class MyDanmakuParser <: BaseDanmakuParser {
    protected var mDispScaleX: Float64 = 0.0
    protected var mDispScaleY: Float64 = 0.0
    let lock = Monitor()

    @OverflowWrapping
    public func parse(): IDanmakus {
        let result = Danmakus()
        if (let Some(v) <- this.mDataSource) {
            let mjson = (v.data() as JsonValue).getOrThrow()
            if (let Some(v) <- mjson.asObject().get("i")) {
                if (let Some(w) <- v.asObject().get("d")) {
                    let z = w.asArray()
                    println(z.size())
                    for (i in 0..z.size()) {
                        let obj = z.get(i).getOrThrow().asObject()
                        var item: ?BaseDanmaku = None
                        /**if (let Some(pValue) <- obj.get("-p")){
                            let values = pValue.asString().getValue().split(",")
                            let time = Int64(Float64.parse(values[0]) * 1000.0)
                            let typ = Int64.parse(values[1])
                            let textSize = Float64.parse(values[2])
                            let color: UInt32 = (0x00000000ff000000 |UInt32.parse(values[3])) & 0x00000000ffffffff
                            item = this.mContext.getOrThrow().mDanmakuFactory.createDanmakuByContext(typ, this.mContext)
                            if (let Some(v) <- item) {
                                v.setTime(time)
                                v.textSize = textSize
                                v.textColor = color
                                v.textShadowColor = if (color <= 0x000000) {0xFFFFFF} else {0x000000}
                            }

                        }
                        if (let Some(test) <- obj.get("#text")){
                            if (let Some(v) <- item) {
                                v.text = test.asString().getValue()
                            }
                        }*/
                        if (let Some(pValue) <- obj.get("DanmakuType")){
                            let typ = pValue.asInt().getValue()
                            if (let Some(danma) <- this.mContext.getOrThrow().mDanmakuFactory.createDanmakuByContext(typ, this.mContext)) {
                                if (let Some(pValue) <- obj.get("time")){
                                    let value = pValue.asInt().getValue()
                                    danma.setTime(value)
                                }
                                if (let Some(pValue) <- obj.get("textSize")){
                                    let value = pValue.asFloat().getValue()
                                    danma.textSize = value * this.mDispDensity * 0.8
                                }
                                if (let Some(pValue) <- obj.get("textColor")){
                                    let value = pValue.asInt().getValue()
                                    danma.textColor = UInt32(value)
                                }
                                if (let Some(pValue) <- obj.get("textShadowColor")){
                                    let value = pValue.asInt().getValue()
                                    danma.textShadowColor = UInt32(value)
                                }
                                if (let Some(pValue) <- obj.get("text")){
                                    let value = pValue.asString().getValue()
//                                    danma.text = value
                                    DanmakuUtils.fillText(danma, value)
                                }
                                if (let Some(pValue) <- obj.get("textSize")){
                                    let value = pValue.asInt().getValue()
                                    danma.index = value
                                }
                                item = danma
                            }
                        }


                        synchronized (lock) {
                            if (let Some(v) <- item) {
                                v.flags = mContext.getOrThrow().mGlobalFlagValues;
                                v.setTimer(this.mTimer.getOrThrow());
                                result.addItem(v)
                            }
                        }
                    }
                }
            }
        }

        return result
    }

    public func setDisplayer(disp: IDisplayer) : BaseDanmakuParser {
        super.setDisplayer(disp)
        this.mDispScaleX = this.mDispWidth / Float64(DanmakuFactory.BILI_PLAYER_WIDTH)
        this.mDispScaleY = this.mDispHeight / Float64(DanmakuFactory.BILI_PLAYER_HEIGHT)
        return this
    }
}

class Pro <: Proxy {
  public func  prepareDrawing(danmaku: BaseDanmaku, fromWorkerThread: Bool): Unit {
  }

  public func releaseResource(danmaku: BaseDanmaku): Unit {
    // TODO 重要:清理含有ImageSpan的text中的一些占用内存的资源 例如drawable
  }
}

class DanmaEntryCall <: DanmakuCallBack {
  private var that: MyView

  init(that: MyView) {
    this.that = that
  }

  public func updateTimer(timer: DanmakuTimer): Unit {
  }

  public func drawingFinished(): Unit {

  }

  public func danmakuShown(danmaku: BaseDanmaku): Unit {
  }

  public func prepared(): Unit {
    that.getModel().start()
  }
}



class JSONSource <: IDataSource {
    var jv : JsonValue
    public init(jv: JsonValue) {
        this.jv = jv
    }

    public func data(): Any {
        jv
    }
    public func release(): Unit {
        ()
    }
}
