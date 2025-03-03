/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class DanmakuUtils {

    /**
     * 检测两个弹幕是否会碰撞
     * 允许不同类型弹幕的碰撞
     * @param d1
     * @param d2
     * @return
     */
    public static func willHitInDuration(disp: IDisplayer, d1: BaseDanmaku, d2: BaseDanmaku, duration: Int64,
        currTime: Int64): Bool {
        let type1: Int64 = d1.getType()
        let type2: Int64 = d2.getType()
        // allow hit if different type
        if (type1 != type2) {
            return false
        }
        if (d1.isOutside()) {
            return false
        }
        let dTime: Int64 = d2.getActualTime() - d1.getActualTime()
        if (dTime <= 0) {
            return true
        }
        if (abs(dTime) >= duration || d1.isTimeOut() || d2.isTimeOut()) {
            return false
        }
        if (type1 == BaseDanmaku.TYPE_FIX_TOP || type1 == BaseDanmaku.TYPE_FIX_BOTTOM) {
            return true
        }
        return DanmakuUtils.checkHitAtTime(disp, d1, d2, currTime)
            || DanmakuUtils.checkHitAtTime(disp, d1, d2, d1.getActualTime() + d1.getDuration())
    }

    private static func checkHitAtTime(disp: IDisplayer, d1: BaseDanmaku, d2: BaseDanmaku, time: Int64): Bool {
        let rectArr1 = d1.getRectAtTime(disp, time)
        let rectArr2 = d2.getRectAtTime(disp, time)
        if (rectArr1.size == 0 || rectArr2.size == 0) {
            return false
        }
        return DanmakuUtils.checkHit(d1.getType(), d2.getType(), rectArr1, rectArr2)
    }

    private static func checkHit(type1: Int64, type2: Int64, rectArr1: Array<Float64>, rectArr2: Array<Float64>): Bool {
        if (type1 != type2) {
            return false
        }
        if (type1 == BaseDanmaku.TYPE_SCROLL_RL) {
            // hit if left2 < right1
            return rectArr2[0] < rectArr1[2]
        }
        if (type1 == BaseDanmaku.TYPE_SCROLL_LR) {
            // hit if right2 > left1
            return rectArr2[2] > rectArr1[0]
        }
        return false
    }

    public static func isDuplicate(obj1: BaseDanmaku, obj2: BaseDanmaku): Bool {
        if (refEq(obj1, obj2)) {
            return false
        }
        if (obj1.text == obj2.text) {
            return true
        }
        return false
    }

    public static func compare(obj1: BaseDanmaku, obj2: BaseDanmaku): Ordering {
        if (refEq(obj1, obj2)) {
            return Ordering.EQ
        }
        let val: Int64 = obj1.getTime() - obj2.getTime()
        if (val > 0) {
            return Ordering.GT
        } else if (val < 0) {
            return Ordering.LT
        }
        var r: Int64 = obj1.index - obj2.index
        if (r != 0) {
            if (r < 0) {
                return Ordering.LT
            } else {
                return Ordering.GT
            }
        }
        r = obj1.hashCode() - obj1.hashCode()
        if (r > 0) {
            return Ordering.GT
        } else if (r < 0) {
            return Ordering.LT
        } else {
            return Ordering.EQ
        }
    }

    public static func fillText(danmaku: BaseDanmaku, text: String): Unit {
        danmaku.text = text
        if (text == "" || text.size == 0 || !text.contains(BaseDanmaku.DANMAKU_BR_CHAR)) {
            return
        }
        let lines: Array<String> = danmaku.text.split(BaseDanmaku.DANMAKU_BR_CHAR)
        if (lines.size > 1) {
            danmaku.lines = lines
        }
    }
}

public open class DefaultJsonDanmakuParser <: BaseDanmakuParser {
    protected var mDispScaleX: Float64 = 0.0
    protected var mDispScaleY: Float64 = 0.0
    let lock = Monitor()

    @OverflowWrapping
    public open func parse(): IDanmakus {
        let result = Danmakus()
        if (let Some(v) <- this.mDataSource) {
            let mjson = (v.data() as JsonValue).getOrThrow()
            let d = mjson.asObject().get("d")
            let z = d.getOrThrow().asArray()

            for (i in 0..z.size()) {
                let oneDanmu = z.get(i).getOrThrow().asObject()
                if (let Some(pvalues) <- oneDanmu.get("p")?.asString().getValue().split(",")){
                        // { "p":"205.2259979248,4,25,6830715,1484219280,0,47f24a19,2839373425", "text":"厉害了我的弹幕君！"},
                        // 0:时间(弹幕出现时间)
                        // 1:类型(1从右至左滚动弹幕|6从左至右滚动弹幕|5顶端固定弹幕|4底端固定弹幕|7高级弹幕|8脚本弹幕)
                        // 2:字号
                        // 3:颜色
                        // 4:时间戳 ?
                        // 5:弹幕池id
                        // 6:用户hash
                        // 7:弹幕id
                    let time: Float64 = parseNumber(pvalues[0])
                    let typ: Int64 = Int64.parse(pvalues[1])
                    let textSize: Float64 = parseNumber(pvalues[2])
                    let color: UInt32 =  UInt32.parse(pvalues[3])
                    let index: Int64 = Int64(parseNumber(pvalues[7]))

                    let danmaItem = this.mContext.getOrThrow().mDanmakuFactory.createDanmakuByContext(typ, this.mContext).getOrThrow()
                    danmaItem.setTime(Int64(time * 1000.0))
                    danmaItem.textSize = textSize * this.mDispDensity * 0.8
                    danmaItem.textColor = color
                    danmaItem.textShadowColor = UInt32(4278190080)
                    danmaItem.index = index
                    danmaItem.flags = mContext.getOrThrow().mGlobalFlagValues;
                    // 必须要加才行
                    danmaItem.setTimer(this.mTimer.getOrThrow());
                    if (let Some(value) <- oneDanmu.get("text")?.asString().getValue()){
                        if (typ == BaseDanmaku.TYPE_SPECIAL && value.startsWith("[") && value.endsWith("]")) {
                            parseSpecialForJson(danmaItem, value)
                        } else {
                            DanmakuUtils.fillText(danmaItem, value)
                        }
                    }
                    result.addItem(danmaItem)
                }
            }

        }

        return result
    }

    // [0,0,\"1-1\",4.5,\"好想和你表白。。。。。\",0,0,0,0,500,0,true,\"黑体\",1]
    func parseSpecialForJson(item: BaseDanmaku, text: String): Unit {
        let arr: JsonArray = JsonValue.fromStr(text).asArray()
        let textArr: Array<String> = Array<String>(arr.size(), item: "")
        for (i in 0..arr.size()) {
            match (arr[i].kind()) {
                case JsonKind.JsInt => textArr[i] = arr[i].asInt().getValue().toString()
                case JsonKind.JsFloat => textArr[i] = arr[i].asFloat().getValue().toString()
                case JsonKind.JsString => textArr[i] = arr[i].asString().getValue()
                case JsonKind.JsBool => textArr[i] = arr[i].asBool().getValue().toString()
                case _ => throw Exception()
            }
        }
        parseSpecialForArray(item, textArr)
    }

    func parseSpecial(item: BaseDanmaku, text: String): Unit {
        parseSpecialForArray(item, text.split(","))
    }
    func parseSpecialForArray(item: BaseDanmaku, textArr: Array<String>): Unit {
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
        item.rotationZ = rotateZ * Float64.PI / 180.0;
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
                        let points = Array<Array<Float64>>(pointStrArray.size, {i=> Array<Float64>(2, item: 0.0)})
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
        try {
            if (text.contains(".")) {
                Float64.parse(text)
            } else {
                Float64(Int64.parse(text))
            }
        } catch (e: IllegalArgumentException) {
            throw e
        }
    }

    public func setDisplayer(disp: IDisplayer) : BaseDanmakuParser {
        super.setDisplayer(disp)
        this.mDispScaleX = this.mDispWidth / Float64(DanmakuFactory.BILI_PLAYER_WIDTH)
        this.mDispScaleY = this.mDispHeight / Float64(DanmakuFactory.BILI_PLAYER_HEIGHT)
        return this
    }
}