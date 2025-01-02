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
        if (let Some(rectArr1) <- d1.getRectAtTime(disp, time)) {
            if (let Some(rectArr2) <- d2.getRectAtTime(disp, time)) {
                return DanmakuUtils.checkHit(d1.getType(), d2.getType(), rectArr1, rectArr2)
            }
        }
        return false
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
