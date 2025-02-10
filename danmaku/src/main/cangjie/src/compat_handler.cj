/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class RunnableRecords <: Equatable<RunnableRecords> {
    static let random: Random = Random()
    let ID: Int64 = random.nextInt64()
    var call: () -> Unit

    public init() {
        call = unsafe {zeroValue<() -> Unit>()}
    }
    public init(run: () -> Unit) {
        call = run
    }

    public func setCall(run: () -> Unit): Unit {
        call = run
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
sealed abstract class Handler {
    var mQueue: DelayedMessageQueue
    var mLooper: MessageLooper
    init(looper: MessageLooper) {
        mLooper = looper
        mQueue = mLooper.mQueue
    }

    public func updateRunnableRecords(r: RunnableRecords, add: Bool, queue: BlockingQueue<Timer>): Unit {
        updateRunnableRecords(r, add, queue.dequeue())
    }

    public func updateRunnableRecords(r: RunnableRecords, add: Bool, taskID: Timer): Unit {
        
    }

    public func dispatchMessage(msg: Message): Unit {
        if (let Some(v) <- msg.callback) {
            v.call()
        } else {
            handleMessage(msg)
        }
    }

    protected func handleMessage(msg: Message): Unit

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
        msg.target = this
        this.mQueue.enqueueMessage(msg, delay)
    }

    // 删除消息
    protected func removeMessages(what: Int64): Unit {
        this.mQueue.removeMessages(this, what)
    }

    protected func post(r: RunnableRecords): Unit {
        sendMessageDelayed(getPostMessage(r), 0)
    }

    private static func getPostMessage(r: RunnableRecords): Message {
        let m = Message(what: 0)
        m.callback = r
        return m
    }

    protected func postDelayed(r: RunnableRecords, delay: Int64) {
        return sendMessageDelayed(getPostMessage(r), delay)
    }

    protected func removeCallbacks(r: RunnableRecords): Unit {
        this.mQueue.removeMessages(this, r)
    }

    protected func removeCallbacksAndMessages(): Unit {
        this.mQueue.removeCallbacksAndMessages(this)
    }
}


