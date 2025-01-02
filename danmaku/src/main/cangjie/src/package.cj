/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

internal import ohos.hilog.*
internal import ohos.base.*
internal import ohos.component.*
internal import ohos.measure.Measure
internal import ohos.base.Color
internal import ohos.system_date_time.*
internal import std.collection.*
internal import std.random.Random
internal import std.time.Duration
internal import std.time.DateTime
internal import std.collection.concurrent.BlockingQueue
internal import std.collection.concurrent.NonBlockingQueue
internal import std.convert.*
internal import std.math.*
internal import std.sync.*
//internal import std.os.posix.nice


// DrawHandler class definitions
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

// let MAX_RECORD_SIZE: Int64 = 500

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

// Convenient to delete when traversing linked lists
open class LinkedlistIteratorWithRemove<T> <: Iterator<T> where T <: Comparable<T> & BaseDanmaku {
    var curr : Option<(T, Unit)>
    var node : Option<(T, Unit)>
    let list: TreeMap<T, Unit>
    public init(list : TreeMap<T, Unit>) {
        this.list = list
        this.curr = list.firstEntry()
        this.node = list.firstEntry()
    }

    func reset(): Unit {
        this.curr = list.firstEntry()
        this.node = list.firstEntry()
    }

    public func next(): ?T {
        if (let Some(v) <- node) {
            let data = v
            this.curr = v
            this.node = if (let Some(m) <- this.list.findUpper(v[0])) {
                Some((m.key, m.value))
            } else {
                None
            }
            return data[0]
        } else {
            None
        }
    }

    public func remove(): Unit {
        if (let Some(v) <- curr) {
            list.remove(v[0])
        }
    }
}


// for test
func printlnException(arr: Array<StackTraceElement> ): String {
    let bugs = StringBuilder()
    for (a in arr) {
        bugs.append("${a.fileName} ${a.declaringClass} ${a.lineNumber} ${a.methodName}\n")
    }
    bugs.toString()

}