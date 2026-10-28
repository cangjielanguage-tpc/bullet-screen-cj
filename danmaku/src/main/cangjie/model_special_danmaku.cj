/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class ScaleFactor {
    var flag: Int64 = 0
    var scaleX: Float64 = 0.0
    var scaleY: Float64 = 0.0
    var width: Float64 = 0.0
    var height: Float64 = 0.0

    init() {}

    init(width: Float64, height: Float64, scaleX: Float64, scaleY: Float64) {
        update(width, height, scaleX, scaleY)
    }

    public func update(width: Float64, height: Float64, scaleX: Float64, scaleY: Float64): Unit {
        if (this.scaleX == scaleX || this.scaleY == scaleY) {
            flag++
        }
        this.width = width
        this.height = height
        this.scaleX = scaleX
        this.scaleY = scaleY
    }

    public func isUpdated(flag: Int64, width: Float64, height: Float64): Bool {
        return flag != flag && (width != width || height != height)
    }
}

public class Point {
    var x: Float64
    var y: Float64

    init(x: Float64, y: Float64) {
        this.x = x
        this.y = y
    }

    public func getDistance(p: Point): Float64 {
        let _x: Float64 = abs(x - p.x)
        let _y: Float64 = abs(y - p.y)
        return sqrt(_x * _x + _y * _y)
    }
}

public class LinePath {
    var pBegin: Point = Point(0.0, 0.0)
    var pEnd: Point = Point(0.0, 0.0)
    public var duration: Int64 = 0
    public var beginTime: Int64 = 0
    public var endTime: Int64 = 0
    var delatX: Float64 = 0.0
    var deltaY: Float64 = 0.0

    public func setPoints(pBegin: Point, pEnd: Point): Unit {
        this.pBegin = pBegin
        this.pEnd = pEnd
        this.delatX = pEnd.x - pBegin.x
        this.deltaY = pEnd.y - pBegin.y
    }

    public func getDistance(): Float64 {
        return pEnd.getDistance(pBegin)
    }

    public func getBeginPoint(): Array<Float64> {
        return [pBegin.x, pBegin.y]
    }

    public func getEndPoint(): Array<Float64> {
        return [pEnd.x, pEnd.y]
    }
}

public class SpecialDanmaku <: BaseDanmaku {
    public var beginX: Float64 = 0.0
    public var beginY: Float64 = 0.0
    public var endX: Float64 = 0.0
    public var endY: Float64 = 0.0
    public var deltaX: Float64 = 0.0
    public var deltaY: Float64 = 0.0
    public var translationDuration: Int64 = 0
    public var translationStartDelay: Int64 = 0
    private var mScaleFactor: ScaleFactor = ScaleFactor()
    private var mScaleFactorChangedFlag: Int64 = 0
    private var mCurrentWidth: Float64 = 0.0
    private var mCurrentHeight: Float64 = 0.0

    /**
     * Linear.easeIn or Quadratic.easeOut
     */
    public var isQuadraticEaseOut: Bool = false
    public var beginAlpha: Int64 = 0
    public var endAlpha: Int64 = 0
    public var deltaAlpha: Int64 = 0
    public var alphaDuration: Int64 = 0
    public var rotateX: Float64 = 0.0
    public var rotateZ: Float64 = 0.0
    public var pivotX: Float64 = 0.0
    public var pivotY: Float64 = 0.0
    private var currStateValues = Array<Float64>(4, repeat: 0.0)
    public var linePaths: ?Array<LinePath> = None

    public override func measure(displayer: IDisplayer, fromWorkerThread: Bool): Unit {
        super.measure(displayer, fromWorkerThread)
        if (mCurrentWidth == 0.0 || mCurrentHeight == 0.0) {
            mCurrentWidth = displayer.getWidth()
            mCurrentHeight = displayer.getHeight()
        }
    }

    public override func layout(displayer: IDisplayer, _: Float64, _: Float64): Unit {
        getRectAtTime(displayer, mTimer().currMillisecond)
    }

    public override func getRectAtTime(_: IDisplayer, currTime: Int64): Array<Float64> {
        if (!isMeasured()) {
            return NullArray
        }
        if (mScaleFactor.isUpdated(mScaleFactorChangedFlag, mCurrentWidth, mCurrentHeight)) {
            let scaleX: Float64 = mScaleFactor.scaleX
            let scaleY: Float64 = mScaleFactor.scaleY
            setTranslationData(beginX * scaleX, beginY * scaleY, endX * scaleX, endY * scaleY, translationDuration,
                translationStartDelay)
            if (let Some(v) <- linePaths) {
                if (v.size > 0) {
                    let length: Int64 = v.size
                    let points: Array<Array<Float64>> = Array<Array<Float64>>(length + 1) {_ => Array<Float64>(2) {_ => 0.0}}
                    for (j in 0..length) {
                        points[j] = v[j].getBeginPoint()
                        points[j + 1] = v[j].getEndPoint()
                    }
                    for (i in 0..points.size) {
                        points[i][0] *= scaleX
                        points[i][1] *= scaleY
                    }
                    setLinePathData(points)
                }
            }
            mScaleFactorChangedFlag = mScaleFactor.flag
            mCurrentWidth = mScaleFactor.width
            mCurrentHeight = mScaleFactor.height
        }

        let deltaTime: Int64 = currTime - getActualTime()

        // calculate alpha
        if (alphaDuration > 0 && deltaAlpha != 0) {
            if (deltaTime >= alphaDuration) {
                alpha = endAlpha
            } else {
                let alphaProgress: Int64 = Int64(Float64(deltaTime) / Float64(alphaDuration))
                let vectorAlpha: Int64 = deltaAlpha * alphaProgress
                alpha = beginAlpha + vectorAlpha
            }
        }
        // calculate x y
        var currX: Float64 = beginX
        var currY: Float64 = beginY
        let dtime: Int64 = deltaTime - translationStartDelay
        if (translationDuration > 0 && dtime >= 0 && dtime <= translationDuration) {
            var tranalationProgress: Float64 = 0.0
            if (let Some(v) <- linePaths) {
                var currentLinePath: ?LinePath = None
                for (line in v) {
                    if (dtime >= line.beginTime && dtime < line.endTime) {
                        currentLinePath = line
                        break
                    } else {
                        currX = line.pEnd.x
                        currY = line.pEnd.y
                    }
                }
                if (let Some(current) <- currentLinePath) {
                    let deltaX: Float64 = current.delatX
                    let deltaY: Float64 = current.deltaY
                    tranalationProgress = (Float64(deltaTime) - Float64(current.beginTime)) / Float64(current.duration)
                    let beginX: Float64 = current.pBegin.x
                    let beginY: Float64 = current.pBegin.y
                    if (deltaX != 0.0) {
                        let vectorX: Float64 = deltaX * tranalationProgress
                        currX = beginX + vectorX
                    }
                    if (deltaY != 0.0) {
                        let vectorY: Float64 = deltaY * tranalationProgress
                        currY = beginY + vectorY
                    }
                }
            } else {
                tranalationProgress = if (isQuadraticEaseOut) {
                    SpecialDanmaku.getQuadEaseOutProgress(dtime, translationDuration)
                } else {
                    Float64(dtime) / Float64(translationDuration)
                }
                if (deltaX != 0.0) {
                    let vectorX: Float64 = deltaX * tranalationProgress
                    currX = beginX + vectorX
                }
                if (deltaY != 0.0) {
                    let vectorY: Float64 = deltaY * tranalationProgress
                    currY = beginY + vectorY
                }
            }
        } else if (dtime > translationDuration) {
            currX = endX
            currY = endY
        }

        currStateValues[0] = currX
        currStateValues[1] = currY
        currStateValues[2] = currX + paintWidth
        currStateValues[3] = currY + paintHeight
        setVisibility(!isOutside())
        return currStateValues
    }

    private static func getQuadEaseOutProgress(ctime: Int64, duration: Int64): Float64 {
        var t: Float64 = Float64(ctime)
        let c: Float64 = 1.0
        let d: Float64 = Float64(duration)
        t /= d
        return -c * t * (t - 2.0)
    }

    public override func getLeft(): Float64 {
        return currStateValues[0]
    }

    public override func getTop(): Float64 {
        return currStateValues[1]
    }

    public override func getRight(): Float64 {
        return currStateValues[2]
    }

    public override func getBottom(): Float64 {
        return currStateValues[3]
    }

    public override func getType(): Int64 {
        return BaseDanmaku.TYPE_SPECIAL
    }

    public func setTranslationData(beginX: Float64, beginY: Float64, endX: Float64, endY: Float64,
        translationDuration: Int64, translationStartDelay: Int64): Unit {
        this.beginX = beginX
        this.beginY = beginY
        this.endX = endX
        this.endY = endY
        this.deltaX = endX - beginX
        this.deltaY = endY - beginY
        this.translationDuration = translationDuration
        this.translationStartDelay = translationStartDelay
    }

    public func setAlphaData(beginAlpha: Int64, endAlpha: Int64, alphaDuration: Int64): Unit {
        this.beginAlpha = beginAlpha
        this.endAlpha = endAlpha
        this.deltaAlpha = endAlpha - beginAlpha
        this.alphaDuration = alphaDuration
        if (beginAlpha != AlphaValue.MAX) {
            alpha = beginAlpha
        }
    }

    public func setLinePathData(points: Array<Array<Float64>>): Unit {
        if (!points.isEmpty()) {
            let length: Int64 = points.size
            this.beginX = points[0][0]
            this.beginY = points[0][1]
            this.endX = points[length - 1][0]
            this.endY = points[length - 1][1]
            if (points.size > 1) {
                linePaths = Array<LinePath>((points.size - 1), repeat: LinePath())
                for (i in 0..linePaths().size) {
                    linePaths()[i] = LinePath()
                    linePaths()[i].setPoints(
                        Point(points[i][0], points[i][1]),
                        Point(points[i + 1][0], points[i + 1][1])
                    )
                }
                var totalDistance: Float64 = 0.0
                for (line in linePaths()) {
                    totalDistance += line.getDistance()
                }
                var lastLine: ?LinePath = None
                for (line in linePaths()) {
                    line.duration = Int64(line.getDistance() / totalDistance) * translationDuration
                    line.beginTime = if (let Some(v) <- lastLine) {
                        v.endTime
                    } else {
                        0
                    }
                    line.endTime = line.beginTime + line.duration
                    lastLine = line
                }
            }
        }
    }

    public func setScaleFactor(scaleFactor: ScaleFactor): Unit {
        this.mScaleFactor = scaleFactor
        this.mScaleFactorChangedFlag = scaleFactor.flag
    }
}
