/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

public abstract class AbsDanmakuSync {
    public static let SYNC_STATE_HALT: Int64 = 1
    public static let SYNC_STATE_PLAYING: Int64 = 2

    /**
     * Get the uptime of timer synchronization
     *
     * @return
     */
    public func getUptimeMillis(): Int64

    /**
     * Get the state of timer synchronization
     *
     * @return SYNC_STATE_HALT or SYNC_STATE_PLAYING
     */
    public func getSyncState(): Int64

    /**
     * Get the threshold-time of timer synchronization
     * This value should be greater than or equal to 1000L
     *
     * @return
     */
    public func getThresholdTimeMills(): Int64 {
        return 1500
    }

    /**
     * synchronize pause/resume state with outside playback
     * @return
     */
    public func isSyncPlayingState(): Bool {
        return false
    }
}
