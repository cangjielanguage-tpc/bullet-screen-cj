/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package ohos_app_cangjie_entry
import ohos.resource_manager.ResourceManager
import ohos.ability.getStageContext
import ohos.hilog.*

import stdx.encoding.json.*
import std.convert.*
import std.sync.*
import std.unicode.*
import std.convert.*

func printlnException(arr: Array<StackTraceElement> ): String {
    let bugs = StringBuilder()
    for (a in arr) {
        bugs.append("${a.fileName} ${a.declaringClass} ${a.lineNumber} ${a.methodName}\n")
    }
    bugs.toString()

}

class ArktsDanmakuParser <: BaseDanmakuParser {
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
                                if (let Some(pValue) <- obj.get("index")){
                                    let value = pValue.asInt().getValue()
                                    danma.index = value
                                }
                                if (let Some(pValue) <- obj.get("text")){
                                    let value = pValue.asString().getValue()
                                    if (typ == BaseDanmaku.TYPE_SPECIAL && value.startsWith("[") && value.endsWith("]")) {
                                        let bytes = value.toRuneArray()
                                        let newText = String(bytes[1..bytes.size-1])
                                        parseSpecial(danma, newText)
                                    } else {
                                        DanmakuUtils.fillText(danma, value)
                                    }
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

    func parseSpecial(item: BaseDanmaku, text: String): Unit {
        let textArr = text.split(",")
        for (i in 0..textArr.size) {
            textArr[i] = textArr[i].trim()
        }
        if (textArr.size < 5 || textArr[4].isEmpty()) {
            return // TODO null
        }
        DanmakuUtils.fillText(item, textArr[4])
        var beginX = parseNumber(textArr[0])
        var beginY = parseNumber(textArr[1])
        var endX = beginX
        var endY = beginY
        let alphaArr = textArr[2].split("-")
        var beginAlpha = Int64(Float64(AlphaValue.MAX) * parseNumber(alphaArr[0]));
        var endAlpha = beginAlpha;
        if (alphaArr.size > 1) {
            endAlpha = Int64(Float64(AlphaValue.MAX) * parseNumber(alphaArr[1]));
        }
        var alphaDuraion =  Int64(parseNumber(textArr[3]) * 1000.0);
        var translationDuration = alphaDuraion;
        var translationStartDelay = 0;
        var rotateY = 0.0
        var rotateZ = 0.0;
        if (textArr.size >= 7) {
            rotateZ = parseNumber(textArr[5]);
            rotateY = parseNumber(textArr[6]);
        }
        if (textArr.size >= 11) {
            endX = parseNumber(textArr[7]);
            endY = parseNumber(textArr[8]);
            if (""!=(textArr[9])) {
                translationDuration = Int64.parse(textArr[9]);
            }
            if (""!=(textArr[10])) {
                translationStartDelay = Int64(parseNumber(textArr[10]));
            }
        }
        if (textArr[0].contains(".")) {
            beginX *= Float64(DanmakuFactory.BILI_PLAYER_WIDTH);
        }
        if (textArr[1].contains(".")) {
            beginY *= Float64(DanmakuFactory.BILI_PLAYER_HEIGHT);
        }
        if (textArr.size >= 8 && textArr[7].contains(".")) {
            endX *= Float64(DanmakuFactory.BILI_PLAYER_WIDTH);
        }
        if (textArr.size >= 9 && textArr[8].contains(".")) {
            endY *= Float64(DanmakuFactory.BILI_PLAYER_HEIGHT);
        }
        item.duration = DanmakuDuration(alphaDuraion);
        item.rotationZ = rotateZ;
        item.rotationY = rotateY;
        this.mContext.getOrThrow().mDanmakuFactory.fillTranslationData(item, beginX,
                            beginY, endX, endY, translationDuration, translationStartDelay, mDispScaleX, mDispScaleY);
        this.mContext.getOrThrow().mDanmakuFactory.fillAlphaData(item, beginAlpha, endAlpha, alphaDuraion);
        if (textArr.size >= 12) {
            // 是否有描边
            if (!textArr[11].isEmpty() && "true" == textArr[11].toAsciiLower()) {
                item.textShadowColor = 0;
            }
        }
        if (textArr.size >= 13) {
            //TODO 字体 textArr[12]
        }
        if (textArr.size >= 14) {
            // Linear.easeIn or Quadratic.easeOut
            if (let Some(v) <- (item as SpecialDanmaku)) {
                v.isQuadraticEaseOut = ("0" == textArr[13])
            }
        }
        if (textArr.size >= 15) {
            // 路径数据
            if ("" != (textArr[14])) {
                var motionPathString: String = textArr[14][1..]
                if (!motionPathString.isEmpty()) {
                    let pointStrArray = motionPathString.split("L");
                    if (pointStrArray.size > 0) {
                        let points = Array<Array<Float64>>(pointStrArray.size, {i=> Array<Float64>(2, repeat: 0.0)})
                        for (i in 0..pointStrArray.size) {
                            let pointArray = pointStrArray[i].split(",");
                            if (pointArray.size >= 2) {
                                points[i][0] = parseNumber(pointArray[0]);
                                points[i][1] = parseNumber(pointArray[1]);
                            }
                        }
                        DanmakuFactory.fillLinePathData(item, points, mDispScaleX,
                                mDispScaleY);
                    }
                }
            }
        }
    }

    func parseNumber(text: String): Float64 {
        if (text.contains(".")) {
            Float64.parse(text)
        } else {
            Float64(Int64.parse(text))
        }
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



class JSONSource <: DanmakuDataSource {
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
