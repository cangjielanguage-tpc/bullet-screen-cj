/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

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

// TODO 改用 对象池 减少 GC
public class Message <: Comparable<Message>{
    var what: Int64
    var obj: Any
    var callback: Option<RunnableRecords>
    var target: ?Handler = None
    var when: Int64 = 0

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

    func recycleUnchecked(): Unit {
        this.what = 0
        this.obj = ()
        this.callback = None
        this.target = None
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

