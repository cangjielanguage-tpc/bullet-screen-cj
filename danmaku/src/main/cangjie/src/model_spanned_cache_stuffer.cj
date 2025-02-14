/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class SpannedCacheStuffer <: SimpleTextCacheStuffer {
    public var index: Int64 = 0
    public override func measure(danmaku: BaseDanmaku, paint: DanmakuPaint, fromWorkerThread: Bool): Unit {
        if (danmaku.text != "" && danmaku.text.startsWith("<img")) {
            let text: String = danmaku.text
            let indexSrcStart: Int64 = if (let Some(v) <- text.indexOf("src=\"")) {
                v + 5
            } else {
                0
            }
            let indexSrcEnd: Int64 = if (let Some(v) <- text.indexOf("\"", indexSrcStart)) {
                v
            } else {
                0
            }
            let src: String = text[indexSrcStart..indexSrcEnd]
            let indexWidthStart: Int64 = if (let Some(v) <- text.indexOf("width=\"")) {
                v + 7
            } else {
                0
            }
            let indexWidthEnd: Int64 = if (let Some(v) <- text.indexOf("\"", indexWidthStart)) {
                v
            } else {
                0
            }
            let optText: String = text[indexWidthStart..indexWidthEnd]
            let width: Float64 = if (let Some(v) <- Float64.tryParse(optText)) {
                v
            } else if (let Some(v) <- Int64.tryParse(optText)) {
                Float64(v)
            } else {
                0.0
            }
            let indexHeightStart: Int64 = if (let Some(v) <- text.indexOf("height=\"")) {
                v + 8
            } else {
                0
            }
            let indexHeightEnd: Int64 = if (let Some(v) <- text.indexOf("\"", indexHeightStart)) {
                v
            } else {
                0
            }
            let optText2: String = text[indexHeightStart..indexHeightEnd]
            let height: Float64 = if (let Some(v) <- Float64.tryParse(optText2)) {
                v
            } else if (let Some(v) <- Int64.tryParse(optText2)) {
                Float64(v)
            } else {
                0.0
            }
            let indexTagEnd: Int64 = if (let Some(v) <- text.indexOf("/>")) {
                v + 2
            } else {
                0
            }
            let pureText: String = text[indexTagEnd..]
            danmaku.text = pureText
            super.measure(danmaku, paint, fromWorkerThread)
            danmaku.paintWidth += width
            danmaku.paintHeight = max(danmaku.paintHeight, height)
            danmaku.obj = ImgObj(src, width, height)
            return
        }
        super.measure(danmaku, paint, fromWorkerThread)
    }

    public override func drawStroke(danmaku: BaseDanmaku, lineText: String, canvas: DanmakuCanvas2D,
        left: Float64, top: Float64, paint: DanmakuPaint): Unit {
        if (danmaku.obj is Unit) {
            super.drawStroke(danmaku, lineText, canvas, left, top, paint)
        }
    }

    public override func drawText(danmaku: BaseDanmaku, lineText: String, canvas: DanmakuCanvas2D,
        left: Float64, top: Float64, paint: DanmakuPaint, fromWorkerThread: Bool, displayerConfig: DisplayerConfig): Unit {
        if (danmaku.obj is Unit) {
            super.drawText(danmaku, lineText, canvas, left, top, paint, fromWorkerThread, displayerConfig)
            return
        }
        let imgInfo: ImgObj = if (let Some(v) <- danmaku.obj as ImgObj) {
            v
        } else {
            ImgObj("", 0.0, 0.0)
        }
        let src: String = imgInfo.src
        let width: Float64 = imgInfo.width
        let height: Float64 = imgInfo.height
        let isAnimation: Bool = danmaku.getIsAnimation()
        let requestRemeasure: Bool = 0 != (danmaku.requestFlags & Int64(BaseDanmaku.FLAG_REQUEST_REMEASURE))
        let requestInvalidate: Bool = 0 != (danmaku.requestFlags & Int64(BaseDanmaku.FLAG_REQUEST_INVALIDATE))
        if (requestInvalidate) {
            danmaku.requestFlags &= !BaseDanmaku.FLAG_REQUEST_INVALIDATE
        }
        var needRestore: Bool = false
        let ascent: Float64 = measureTextHeight(paint) * -0.9
        if (left != 0.0 && top != 0.0) {
            canvas.save()
            canvas.translate(left, (top + ascent))
            needRestore = true
        }
        if (isAnimation) {
            let pixelMapList: ArrayList<PixelMap> = danmaku.getPixelMapList()
            index = index % pixelMapList.size
            canvas.drawImage(pixelMapList[index], 0.0, 0.0, width, height)
            index++
            applyPaintToCanvas(paint, canvas)
            if (needRestore) {
                canvas.translate(0.0, -ascent)
            }
            canvas.fillText(danmaku.text, width, 0.0)
        } else if (!isAnimation) {
            let imageBitmap: ImageBitmap = if (let Some(v) <- bitmaps) {  // TODO  LRU 优化
                v.get(src) ?? {=>
                    let bm = ImageBitmap(src)
                    v.put(src, bm)
                    return bm
                }()
            } else {
                ImageBitmap(src)
            }
            canvas.drawImage(imageBitmap, 0.0, 0.0, width, height)
            canvas.fillStyle(0x8A2233B1) // #8A2233B1
            var rectWidth: Float64 = danmaku.paintWidth - width - 2.0 * danmaku.padding
            if (danmaku.borderColor != 0) {
                rectWidth -= 2.0 * displayerConfig.BORDER_WIDTH
            }
            canvas.fillRect(width, 0.0, rectWidth, height)
            applyPaintToCanvas(paint, canvas)
            if (needRestore) {
                canvas.translate(0.0, -ascent)
            }
            canvas.fillText(danmaku.text, width, 0.0)
        }
        if (needRestore) {
            canvas.restore()
        }
    }

    public override func clearCaches(): Unit {
        super.clearCaches()
    }
}

class ImgObj {

    // 图片对象源
    var src: String

    // 图片对象宽度
    var width: Float64

    // 图片对象高度
    var height: Float64

    init(src: String, width: Float64, height: Float64) {
        this.src = src
        this.width = width
        this.height = height
    }
}
