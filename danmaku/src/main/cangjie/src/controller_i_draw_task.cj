/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public let PLAY_STATE_PLAYING = 1
public let PLAY_STATE_PAUSE = 2

public let UNKNOWN_TIME = -1

public interface TaskListener {
    public func ready(): Unit

    public func onDanmakuAdd(danmaku: BaseDanmaku ): Unit

    public func onDanmakuShown(danmaku: BaseDanmaku): Unit

    public func onDanmakuConfigChanged(): Unit

    public func onDanmakusDrawingFinished(): Unit
}

public abstract class IDrawTask {

    public func addDanmaku(item: BaseDanmaku ): Unit

    public func removeAllDanmakus(isClearDanmakusOnScreen: Bool ): Unit

    public func removeAllLiveDanmakus(): Unit

    public func clearDanmakusOnScreen(currMillis: Int64): Unit

	public func getVisibleDanmakusOnTime(time: Int64): IDanmakus

    public func draw(displayer: Any): ?RenderingState

    public func reset(): Unit

    public func seek(mills: Int64): Unit

    public func start(): Unit

    public func quit(): Unit

    public func prepare(): Unit

    public func onPlayStateChanged(state: Int64): Unit

    public func requestClear(): Unit

    public func requestClearRetainer(): Unit

    public func requestSync(fromTimeMills: Int64, toTimeMills: Int64, offsetMills: Int64): Unit

    public func setParser(parser: BaseDanmakuParser ): Unit

    public func invalidateDanmaku(item: BaseDanmaku , remeasure: Bool ): Unit

    public func requestHide(): Unit

    public func requestRender(): Unit
}
