/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class SpannedCacheStuffer <: SimpleTextCacheStuffer {
    public var index: Int64 = 0
    public override func measure(danmaku: BaseDanmaku, paint: DanmakuPaint, fromWorkerThread: Bool): Unit {
        super.measure(danmaku, paint, fromWorkerThread)
        if (let Some(image) <- danmaku.image) {
            danmaku.paintWidth += image.width
            danmaku.paintHeight = max(danmaku.paintHeight, image.height)
            danmaku.obj = image
        }
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

public class ImgObj {

    // 图片对象源
    var src: String

    // 图片对象宽度
    var width: Float64

    // 图片对象高度
    var height: Float64

    public init(src: String, width: Float64, height: Float64) {
        this.src = src
        if (width < 0.0 || height < 0.0) {
            throw IllegalArgumentException()
        }
        this.width = width
        this.height = height
    }
}
