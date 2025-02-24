/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

class MessageTreeSet {
    private var list: TreeMap<Message, Unit> = TreeMap<Message, Unit>()
    func add(msg: Message): Unit {
        this.list.put(msg, ())
    }

    func isEmpty(): Bool {
        this.list.isEmpty()
    }

    func peek(): Message {
        if (let Some(v) <- this.list.firstEntry()) {
            return v[0]
        }
        throw NoneValueException()
    }

    func poll(): Message {
        if (let Some(v) <- this.list.popFirstEntry()) {
            return v[0]
        }
        throw NoneValueException()
    }

    func removeIf(predicate: (Message) -> Bool): Unit{
        this.list.removeIf({k, v =>
            if (predicate(k)){
                return true
            }
            return false
        })
    }

    func clear(): Unit {
        this.list.clear()
    }
}

public class DelayedMessageQueue {
    private let set: MessageTreeSet = MessageTreeSet()
    private let lock: MultiConditionMonitor  = MultiConditionMonitor()
    private var notEmpty: ConditionID
    var mQuitting: Bool = false
    public init() {
        synchronized(lock) {
            notEmpty = lock.newCondition()
        }
    }

    public func enqueueMessage(msg: Message , delayMillis: Int64): Unit {
        lock.lock();
        try {
            let now = SystemClock.uptimeMillis()
            msg.when = now + delayMillis;
            set.add(msg);
            lock.notify(notEmpty); // 唤醒等待的线程
        } finally {
            lock.unlock();
        }
    }

    // 出队消息（阻塞直到有消息到期）
    public func next():?Message {
        lock.lock();
        try {
            while (true) {
                // 队列为空时阻塞等待
                while (set.isEmpty()) {
                    lock.wait(notEmpty)
                }
                let msg: Message = set.peek()
                let now = SystemClock.uptimeMillis()
                let delay = msg.when - now;
                // 消息已到期，直接返回
                if (delay <= 0) {
                    return set.poll();
                }
                // 等待至消息到期（避免忙等待）
                lock.wait(notEmpty, timeout: Duration.millisecond * delay);
            }
            return None
        } finally {
            lock.unlock();
        }
    }

    public func removeCallbacksAndMessages(h: Handler): Unit {
        synchronized(lock) {
            set.removeIf({k =>
                if (refEq(k.target.getOrThrow(), h)) {
                    return true
                }
                return false
            })
        }
    }

    public func removeMessages(h: Handler, r: RunnableRecords): Unit {
        synchronized(lock) {
            set.removeIf({k =>
                match (k.callback) {
                    case Some(w) =>
                        return refEq(k.target.getOrThrow(), h) && refEq(w, r)
                    case _ => false
                }
            })
        }
    }

    public func removeMessages(h: Handler, what: Int64): Unit {
        synchronized(lock) {
            set.removeIf({k =>
                return refEq(k.target.getOrThrow(), h) && k.what == what
            })
        }
    }

    public func recycle() {
        synchronized(lock) {
            this.set.clear()
        }
    }

    public func quit() {
        synchronized(lock) {
            this.mQuitting = true
            this.set.clear()
        }
    }
}


class MessageLooper {

    static let sThreadLocal: ThreadLocal<MessageLooper> = ThreadLocal<MessageLooper>()

    let mThread: Thread

    let mQueue: DelayedMessageQueue

    var running: Bool = false

    var mQuit: Bool = false

    init(quitAllowed: Bool) {
        this.mQueue = DelayedMessageQueue()
        this.mQuit = quitAllowed
        this.mThread = Thread.currentThread
    }

    public static func prepare() {
        if (let Some(v) <- sThreadLocal.get()) {
            throw Exception("Only one Looper may be created per thread");
        }
        sThreadLocal.set(MessageLooper(true))
    }

    static func myLooper(): MessageLooper {
        if (let Some(v) <- sThreadLocal.get()) {
            return v
        }  else {
            throw Exception("No Looper; Looper.prepare() wasn't called on this thread.")
        }
    }

    // kan
    public static func loop () {
        let me = myLooper()
        let queue: DelayedMessageQueue = me.mQueue
        while(true) {
            if(let Some(msg: Message) <- queue.next()) {
                msg.target?.dispatchMessage(msg)
                msg.recycleUnchecked()
            } else {
                break
            }
        }
    }

}

