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
            try {
                this.mTid = Thread.currentThread.id
                Thread.currentThread.name = this.name
                MessageLooper.prepare()
                synchronized(multiLock) {
                    this.mLooper = MessageLooper.myLooper()
                    multiLock.notify(notEmpty)
                }
                //nice(this.mPriority)
                MessageLooper.loop()
                this.mTid = -1
                isAlive.store(false)
            } catch (e: Exception) {
                Hilog.error(999, "danmaku4cj", "e: ${e},\n ${printlnException(e.getStackTrace())}")
            }
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
        let looper = getLooper()
        if (let Some(v) <- looper) {
            v.mQuit = true
            v.mQueue.quit()
        }
        this.thread?.cancel()
        return false
    }

}

public open class ExecutorService {
    let map = ConcurrentHashMap<Int64, Future<Unit>>()
    let TASK = BlockingQueue<() -> Unit>()
    let shutdownTASK = BlockingQueue<Int64>()
    let mon = Monitor()
    let threadId = BlockingQueue<Int64>()
    public init() {}

    public static func new(): ExecutorService {
        let service = ExecutorService()
        service.reset()
        spawn {
            while (true) {
                let shutdownId = service.shutdownTASK.dequeue()
                if (let Some(v) <- service.map.get(shutdownId)) {
                    v.cancel()
                    service.map.remove(shutdownId)
                    service.reset()
                } else {
                    break
                }
            }
        }
        return service
    }

    private func reset() {
        let thread: Future<Unit> = spawn {
            threadId.enqueue(Thread.currentThread.id)
            while (true) {
                let fn = this.TASK.dequeue()
                fn()
                sleep(Duration.millisecond* 10)
                mon.lock()
                mon.notifyAll()
                mon.unlock()
            }
        }
        this.map.put(threadId.dequeue(), thread)
    }

    public func execute(fn: () -> Unit): Unit {
        this.TASK.enqueue(fn)
    }

    public func shutdown() {
        for ((id, _) in this.map) {
            shutdownTASK.enqueue(id)
        }
    }

    public func close (isBusy:Bool, fn: () -> Unit) {
        spawn {
            if (isBusy) {
                mon.lock()
                mon.wait()
                mon.unlock()
            }
            fn()
            for ((id, _) in this.map) {
                shutdownTASK.enqueue(id)
            }
        }
    }
}





