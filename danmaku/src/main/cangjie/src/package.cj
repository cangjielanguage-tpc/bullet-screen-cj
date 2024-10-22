/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

internal import ohos.base.*
internal import ohos.component.*
internal import ohos.measure.Measure
internal import ohos.base.Color
internal import std.collection.HashMap
internal import std.collection.HashMapIterator
internal import std.collection.ArrayList
internal import std.collection.LinkedList
internal import std.random.Random
internal import std.sync.Timer
internal import std.time.Duration
internal import std.time.DateTime
internal import std.collection.concurrent.BlockingQueue
internal import std.convert.*
internal import std.math.*

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