/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

import std.objectpool.*

internal class Args {
    var what: Int64 = 0
    var obj: Any
    var callback: Option<RunnableRecords>

    public init(what!: Int64, obj!: Any = (), callback!: Option<RunnableRecords> = None) {
        this.what = what
        this.obj = obj
        this.callback = callback
    }
}

public class Message <: Comparable<Message>{
    var what: Int64
    var obj: Any
    var callback: Option<RunnableRecords>
    var when: Int64 = 0
    var target: ?Handler = None

    static let objectPool = ObjectPool<Message>(
        {=> Message(what: 0)},
        resetFunc: {m: Message =>
            m.what = 0
            m.obj = ()
            m.callback = None
            m.target = None
            m.when = 0
            return m
        }
    )

    internal init(what!: Int64, obj!: Any = (), callback!: Option<RunnableRecords> = None) {
        this.what = what
        this.obj = obj
        this.callback = callback
    }

    internal init(args: Args) {
        this.what = args.what
        this.obj = args.obj
        this.callback = args.callback
    }

    static func obtain(): Message {
        return objectPool.get()
    }

    static func obtain(h: Handler): Message {
        let msg = objectPool.get()
        msg.target = h
        return msg
    }

    static func obtain(h: Handler, what: Int64): Message {
        let msg = objectPool.get()
        msg.what = what
        msg.target = h
        return msg
    }

    static func obtain(h: Handler, what: Int64, obj: Any): Message {
        let msg = objectPool.get()
        msg.what = what
        msg.target = h
        msg.obj = obj
        return msg
    }

    
    public func sendToTarget(){
        this.target?.sendMessage(this)
    }
    
    func recycleUnchecked(): Unit {
        objectPool.put(this)
    }

    public operator func ==(that: Message): Bool {
        return refEq(this, that)
    }

    public operator func !=(that: Message): Bool {
        return !refEq(this, that)
    }
    public operator func <(that: Message): Bool {
        return this.when < that.when
    }
    public operator func <=(that: Message): Bool {
        return this.when <= that.when
    }
    public operator func >(that: Message): Bool {
        return this.when > that.when
    }
    public operator func >=(that: Message): Bool {
        return this.when >= that.when
    }

    public func compare(that: Message): Ordering {
        return if (this.when > that.when) {
            Ordering.GT
        } else if (this.when < that.when) {
            Ordering.LT
        } else {
            Ordering.EQ
        }
    }
}


