/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public abstract class Renderer <: IRenderer {
    public func draw(disp: IDisplayer, danmakus: IDanmakus, startRenderTime: Int64, renderingState: RenderingState): Unit

    public func clear(): Unit

    public func clearRetainer(): Unit

    public func release(): Unit

    public func setVerifierEnabled(enabled: Bool): Unit

    public func setOnDanmakuShownListener(onDanmakuShownListener: OnDanmakuShownListener): Unit

    public func removeOnDanmakuShownListener(): Unit

    public func alignBottom(enable: Bool): Unit
}
