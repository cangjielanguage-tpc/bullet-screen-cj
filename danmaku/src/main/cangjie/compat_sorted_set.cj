/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class SortedSet<T> <: Collection<T> {
    let list: ArrayList<T>
    var compare: ?(T, T) -> Ordering = None
    let mLockObject: ReentrantMutex = ReentrantMutex()

    public init() {
        this.list = ArrayList<T>()
    }
    public init(compare: (T, T) -> Ordering) {
        this.list = ArrayList<T>()
        this.compare = compare
    }

    public prop size: Int64 {
        get() {
            synchronized(mLockObject) {
                return this.list.size
            }
        }
    }
    public func clear(): Unit {
        synchronized(mLockObject) {
            this.list.clear()
        }
    }

    public func isEmpty(): Bool {
        synchronized(mLockObject) {
            this.list.isEmpty()
        }
    }

    public func iterator(): Iterator<T> {
        synchronized(mLockObject) {
            return this.list.clone().iterator()
        }
    }

    public func getFirst(): ?T {
        synchronized(mLockObject) {
            this.list.get(0)
        }
    }

    public func getLast(): ?T {
        synchronized(mLockObject) {
            this.list.get(this.list.size - 1)
        }
    }

    public func get(index: Int64): T {
        synchronized(mLockObject) {
            this.list[index]
        }
    }

    public func subSet(fromElement: T, toElement: T): SortedSet<T> {
        synchronized(mLockObject) {
            if (let Some(v) <- compare) {
                let arr = unsafe {this.list.getRawArray()[0..this.list.size]}
                var indexFrom = arr.size
                var indexTo = -1
                for (i in 0..arr.size) {
                    if (v(fromElement, arr[i]) == Ordering.LT) {
                        indexFrom = i
                        break
                    }
                }
                for (i in arr.size-1..=0:-1 ) {
                    if (v(toElement, arr[i]) == Ordering.GT) {
                        indexTo = i
                        break
                    }
                }
                if (indexFrom > indexTo) {
                    return SortedSet<T>(v)
                }
                let sub = SortedSet<T>(v)
                sub.list.add(all: arr[indexFrom..=indexTo])
                return sub
            }
            return this
        }
    }

    public func add(element: T): Unit {
        synchronized(mLockObject) {
            this.list.add(element)
            if (let Some(v) <- compare) {
                this.list.sortBy(stable: false, comparator: v)
            }
        }
    }

    public func append(element: T): Unit {
        synchronized(mLockObject) {
            this.list.add(element)
            if (let Some(v) <- compare) {
                this.list.sortBy(stable: false, comparator: v)
            }
        }
    }

    public func appendAll(elements: Collection<T>): Unit {
        synchronized(mLockObject) {
            this.list.add(all: elements)
            if (let Some(v) <- compare) {
                this.list.sortBy(stable: false, comparator: v)
            }
        }
    }

    public func insert(index: Int64, element: T): Unit {
        synchronized(mLockObject) {
            this.list[index] = element
            if (let Some(v) <- compare) {
                this.list.sortBy(stable: false, comparator: v)
            }
        }
    }

    public func contains(item: T): Bool {
        synchronized(mLockObject) {
            if (let Some(v) <- compare) {
                for (i in 0..this.list.size where v(item, this.list[i]) == EQ) {
                    return true
                }
            }
            return false
        }
    }

    public func remove(item: T): Bool {
        synchronized(mLockObject) {
            if (let Some(v) <- compare) {
                for (i in 0..this.list.size where v(item, this.list[i]) == EQ) {
                    this.list.remove(at: i)
                    return true
                }
            }
            return false
        }
    }

    public func remove(index: Int64): T {
        synchronized(mLockObject) {
            this.list.remove(at: index)
        }
    }
}

extend<T> SortedSet<T> <: ToString where T <: ToString {
    public func toString(): String {
        synchronized(mLockObject) {
            list.toString()
        }
    }
}

