/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class GlobalFlagValues {
    public var MEASURE_RESET_FLAG: Int64 = 0
    public var VISIBLE_RESET_FLAG: Int64 = 0
    public var FILTER_RESET_FLAG: Int64 = 0
    public var FIRST_SHOWN_RESET_FLAG: Int64 = 0
    public var SYNC_TIME_OFFSET_RESET_FLAG: Int64 = 0
    public var PREPARE_RESET_FLAG: Int64 = 0

    public func resetAll() {
        MEASURE_RESET_FLAG = 0
        VISIBLE_RESET_FLAG = 0
        FILTER_RESET_FLAG = 0
        FIRST_SHOWN_RESET_FLAG = 0
        SYNC_TIME_OFFSET_RESET_FLAG = 0
        PREPARE_RESET_FLAG = 0
    }

    public func updateAll() {
        MEASURE_RESET_FLAG++
        VISIBLE_RESET_FLAG++
        FILTER_RESET_FLAG++
        FIRST_SHOWN_RESET_FLAG++
        SYNC_TIME_OFFSET_RESET_FLAG++
        PREPARE_RESET_FLAG++
    }

    public func updateMeasureFlag(): Unit {
        MEASURE_RESET_FLAG++
    }
    public func updateVisibleFlag(): Unit {
        VISIBLE_RESET_FLAG++
    }
    public func updateFilterFlag(): Unit {
        FILTER_RESET_FLAG++
    }
    public func updateFirstShownFlag(): Unit {
        FIRST_SHOWN_RESET_FLAG++
    }
    public func updateSyncOffsetTimeFlag(): Unit {
        SYNC_TIME_OFFSET_RESET_FLAG++
    }
    public func updatePrepareFlag(): Unit {
        PREPARE_RESET_FLAG++
    }
}
