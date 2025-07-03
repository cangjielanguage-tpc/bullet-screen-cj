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

const POOL_COUNT: Int64 = 50

class ObjectPool<T> where T <: Object {
    var pool: Array<ConcurrentLinkedQueue<T>>
    let newFunc: () -> T
    let resetFunc: Option<(T) -> T>

    public init(newFunc: () -> T, resetFunc!: Option<(T) -> T> = None) {
        pool = Array(Int64(POOL_COUNT), {_ => ConcurrentLinkedQueue<T>()})
        this.newFunc = newFunc
        this.resetFunc = resetFunc
    }

    public func get(): T {
        if (pool.size == 0) {
            pool = Array(Int64(POOL_COUNT), {_ => ConcurrentLinkedQueue<T>()})
        }
        if (let Some(object) <- pool[Int64(Thread.currentThread.id % POOL_COUNT)].remove()) {
            if (let Some(resetFn) <- resetFunc) {
                return resetFn(object)
            }
            return object
        }

        if (let Some(resetFn) <- resetFunc) {
            return resetFn(newFunc())
        }
        return newFunc()
    }

    public func put(item: T): Unit {
        if (pool.size == 0) {
            pool = Array(Int64(POOL_COUNT), {_ => ConcurrentLinkedQueue<T>()})
        }
        pool[Int64(Thread.currentThread.id % POOL_COUNT)].add(item)
    }

    public func release(): Unit {
        pool = []
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

    static func release(): Unit {
        objectPool.release()
    }

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

    
    public func sendToTarget(): Unit {
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


