/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package danmaku

internal class Args {
    var what: Int64 = 0
    var obj: Option<CJResource>
    var callback: Option<() -> Unit>

    public init(what!: Int64, obj!: Option<CJResource> = None, callback!: Option<() -> Unit> = None) {
        this.what = what
        this.obj = obj
        this.callback = callback
    }
}

public class Message {
    var what: Int64 = 0
    var obj: Option<CJResource>
    var callback: Option<() -> Unit>

    internal init(what!: Int64, obj!: Option<CJResource> = None, callback!: Option<() -> Unit> = None) {
        this.what = what
        this.obj = obj
        this.callback = callback
    }

    internal init(args: Args) {
        this.what = args.what
        this.obj = args.obj
        this.callback = args.callback
    }
}

internal class RunnableRecords <: Hashable & Equatable<RunnableRecords> {
    static let random: Random = Random()
    let ID: Int64 = random.nextInt64()
    var call: () -> Unit

    public init(run: () -> Unit) {
        call = run
    }

    public override func hashCode(): Int64 {
        MULTIPLIERVALUE * ID
    }

    public operator override func ==(that: RunnableRecords): Bool {
        return refEq(this, that)
    }

    public operator override func !=(that: RunnableRecords): Bool {
        return !refEq(this, that)
    }
}

// 1. 可设置消息延时响应时间
// 2. 可移除尚未处理的消息
internal open class Handler {
    var msgRecords: HashMap<Int64, LinkedList<Timer>> = HashMap<Int64, LinkedList<Timer>>()
    var runnableRecords: HashMap<RunnableRecords, LinkedList<Timer>> = HashMap<RunnableRecords, LinkedList<Timer>>()

    private func updateMsgRecords(what: Int64, add: Bool, queue: BlockingQueue<Timer>): Unit {
        updateMsgRecords(what, add, queue.dequeue())
    }

    private func updateMsgRecords(what: Int64, add: Bool, taskID: Timer): Unit {
        if (let Some(v) <- msgRecords.get(what)) {
            if (add) {
                v.append(taskID)
            } else {
                v.removeIf({
                    item => if (item == taskID) {
                        taskID.cancel()
                        true
                    } else {
                        false
                    }
                })
            }
        } else {
            let arr: LinkedList<Timer> = LinkedList<Timer>()
            msgRecords.put(what, arr)
            if (add) {
                arr.append(taskID)
            }
        }
    }

    public func updateRunnableRecords(r: RunnableRecords, add: Bool, queue: BlockingQueue<Timer>): Unit {
        updateRunnableRecords(r, add, queue.dequeue())
    }

    public func updateRunnableRecords(r: RunnableRecords, add: Bool, taskID: Timer): Unit {
        if (let Some(v) <- runnableRecords.get(r)) {
            if (add) {
                v.append(taskID)
            } else {
                v.removeIf({
                    item => if (item == taskID) {
                        taskID.cancel()
                        true
                    } else {
                        false
                    }
                })
                if (v.size == 0) {
                    runnableRecords.remove(r)
                }
            }
        } else {
            let arr: LinkedList<Timer> = LinkedList<Timer>()
            runnableRecords.put(r, arr)
            if (add) {
                arr.append(taskID)
            }
        }
    }

    private func dispatchMessage(msg: Message): Unit {
        if (let Some(v) <- msg.callback) {
            v()
        } else {
            handleMessage(msg)
        }
    }

    protected open func handleMessage(msg: Message): Unit {}

    protected open func sendMessage(msg: Message): Unit {
        sendMessageDelayed(msg, 0)
    }

    protected open func sendEmptyMessageDelayed(what: Int64, delay: Int64): Unit {
        sendMessageDelayed(Message(what: what), delay)
    }

    protected open func sendEmptyMessage(what: Int64): Unit {
        sendMessage(Message(what: what))
    }

    // 延迟发送消息
    protected open func sendMessageDelayed(msg: Message, delay: Int64): Unit {
        let queue = BlockingQueue<Timer>(1)
        let time = Timer.once(
            Duration.millisecond * delay,
            {
                =>
                updateMsgRecords(msg.what, false, queue)
                dispatchMessage(msg)
            }
        )
        queue.enqueue(time)
        updateMsgRecords(msg.what, false, queue)
    }

    // 删除消息
    protected func removeMessages(what: Int64): Unit {
        if (let Some(ids) <- msgRecords.get(what)) {
            while (ids.size > 0) {
                let taskID = ids.popFirst()
                taskID?.cancel()
            }
            msgRecords.remove(what)
        }
    }

    protected func post(r: RunnableRecords): Unit {
        post
    }

    protected func postDelayed(r: RunnableRecords, delay: Int64) {
        let queue: BlockingQueue<Timer> = BlockingQueue<Timer>(1)
        let time: Timer = Timer.once(
            Duration.millisecond * delay,
            {
                =>
                updateRunnableRecords(r, false, queue)
                r.call()
            }
        )
        queue.enqueue(time)
        updateRunnableRecords(r, true, time)
    }

    protected func removeCallbacks(r: RunnableRecords): Unit {
        if (let Some(ids) <- runnableRecords.get(r)) {
            while (ids.size > 0) {
                let taskID: Option<Timer> = ids.popFirst()
                taskID?.cancel()
            }
            runnableRecords.remove(r)
        }
    }

    protected func removeCallbacksAndMessages(): Unit {
        let it1: HashMapIterator<Int64, LinkedList<Timer>> = msgRecords.iterator()
        it1.forEach({
            kv: (Int64, LinkedList<Timer>) => removeMessages(kv[0])
        })
        let it2 = runnableRecords.iterator()
        it2.forEach({
            kv => removeCallbacks(kv[0])
        })
    }
}
