/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

/* 
public func nice(inc: Int32): Int32
功能：更改当前线程的优先级。
 */
public class HandlerThread {
    var mPriority: Int32
    var mTid: Int64
    let name: String
    var mLooper: ?MessageLooper = None
    let isAlive = AtomicBool(false)
    let multiLock: MultiConditionMonitor = MultiConditionMonitor()
    let notEmpty: ConditionID
    var thread: ?Future<Unit> = None
    public init(name: String, priority: Int32) {
        this.name = name
        this.mPriority = priority
        this.mTid = -1
        synchronized (multiLock) {
            notEmpty = multiLock.newCondition()
        }
    }


    public func run() {
        isAlive.store(true)
        this.thread = spawn {
            this.mTid = Thread.currentThread.id
            Thread.currentThread.name = this.name
            MessageLooper.prepare()
            synchronized(multiLock) {
                this.mLooper = MessageLooper.myLooper()
                multiLock.notify(notEmpty)
            }
            nice(this.mPriority)
            MessageLooper.loop()
            this.mTid = -1
            isAlive.store(false)
        }
    }

    func getLooper(): ?MessageLooper{
        if (this.isAlive.load()) {
            synchronized(multiLock) {
                multiLock.wait(notEmpty)
            }
        } else {
            return None
        }
        return this.mLooper
    }

    public func quit() {
        if (let Some(v) <- mLooper) {
            v.mQuit = true
            v.running = false
            v.mQueue.quit()
        }
        this.thread?.cancel()
    }

}



