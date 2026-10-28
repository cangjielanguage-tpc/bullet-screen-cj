/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

internal import ohos.hilog.*
internal import ohos.base.*
internal import ohos.component.*
internal import ohos.state_manage.*
internal import ohos.measure.Measure
internal import ohos.system_date_time.*
internal import ohos.image.PixelMap
internal import ohos.animator.*
internal import ohos.prompt_action.*
internal import std.collection.ArrayList
internal import std.collection.HashMap
internal import std.collection.HashMapIterator
internal import std.collection.TreeMap
internal import std.collection.LinkedList
internal import std.random.Random
internal import std.time.*
internal import std.collection.concurrent.*
internal import std.convert.*
internal import std.math.*
internal import std.sync.*
internal import std.unicode.*
internal import std.posix.nice
internal import stdx.encoding.json.*


let START: Int64 = 1
let UPDATE: Int64 = 2
let RESUME: Int64 = 3
let SEEK_POS: Int64 = 4
let PREPARE: Int64 = 5
let QUIT: Int64 = 6
let PAUSE: Int64 = 7
let SHOW_DANMAKUS: Int64 = 8
let HIDE_DANMAKUS: Int64 = 9
let NOTIFY_DISP_SIZE_CHANGED: Int64 = 10
let NOTIFY_RENDERING: Int64 = 11
let UPDATE_WHEN_PAUSED: Int64 = 12
let CLEAR_DANMAKUS_ON_SCREEN: Int64 = 13
let FORCE_RENDER: Int64 = 14
let INDEFINITE_TIME: Int64 = 10000000
// DrawHandler class definitions end

let MULTIPLIERVALUE: Int64 = 37
let ALPHA_MAX: Int64 = 255
let ALPHA_TRANSPARENT: Int64 = 0
let NOTHING_RENDERING: Int64 = 0
let CACHE_RENDERING: Int64 = 1
let TEXT_RENDERING: Int64 = 2

extend<T> Option<T> {
    operator func ()(): T {
        this.getOrThrow()
    }
}

