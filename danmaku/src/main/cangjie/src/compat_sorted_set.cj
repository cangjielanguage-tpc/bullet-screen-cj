/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */

package danmaku

public class SortListNode<T> {
    SortListNode(var prev!: ?SortListNode<T>, var value!: T, var next!: ?SortListNode<T>) {}
}

public class SortedSet<T> <: Collection<T> where  T <: BaseDanmaku{
    var mySize: Int64 = 0
    var first: ?SortListNode<T> = None
    var last: ?SortListNode<T> = None
    var compare: ?(T, T) -> Ordering = None


    public init() {}
    public init(compare:(T, T) -> Ordering) {
        this.compare = compare
    }

    public prop size: Int64 {
        get() {
            return this.mySize
        }
    }
    public func clear(): Unit {
        this.mySize = 0
        this.first = None
        this.last = None
    }

    public func isEmpty(): Bool {
        this.mySize == 0
    }

    public func iterator(): Iterator<T> {
        SortListIterator(this)
    }

    public func getFirst(): T {
        return match (this.first) {
            case Some(v) => v.value
            case _ => throw IndexOutOfBoundsException()
        }
    }

    public func getLast(): T {
        return match (this.last) {
            case Some(v) => v.value
            case _ => throw IndexOutOfBoundsException()
        }
    }

    public func get(index: Int64): T {
        if (index < 0 || index >= this.mySize) {
            throw IndexOutOfBoundsException()
        }
        match (at(index)) {
            case Some(v) => v.value
            case _ => throw IndexOutOfBoundsException()
        }
    }

    public func set(index: Int64, element: T): T {
        if (index < 0 || index >= this.mySize) {
            throw IndexOutOfBoundsException()
        }
        match (at(index)) {
            case Some(v) =>
                let oldValue = v.value
                v.value = element
                return oldValue
            case _ => throw IndexOutOfBoundsException()
        }
    }

    public func prepend(element: T): Unit {
        this.linkFirst(element)
    }

    func findMiddle(index: Int64): Int64 {
        return if ((index & 1) == 1){
            (index - 1) >> 1
        } else {
            index >> 1
        }
    }


    public func contains(item: T): Bool {
        var curr = this.first
        var index = 0
        if (let Some(compareMethod) <- this.compare) {
            while (let Some(v) <- curr) {
                if (compareMethod(item, v.value) == EQ && item == v.value) {
                    return true
                }
                index++
                curr = v.next
            }
        }
        return false
    }

    public func subSet(fromElement: T, toElement: T): SortedSet<T> {
        var indexFrom: Int64 = this.mySize
        var indexTo: Int64 = -1
        if (let Some(compareMethod) <- this.compare) {
            if (compareMethod(fromElement, toElement) == Ordering.GT) {
                return SortedSet<T>(compareMethod)
            }
            var curr = this.first
            var index = 0
            while (let Some(v) <- curr) {
                if (compareMethod(fromElement, v.value) == LT) {
                    indexFrom = index
                    break
                }
                index++
                curr = v.next
            }
            curr = this.last
            index = this.mySize - 1
            while (let Some(v) <- curr) {
                if (compareMethod(toElement, v.value) == GT ) {
                    indexTo = index
                    break
                }
                index--
                curr = v.prev
            }
        }
        let result = SortedSet<T>()
        result.compare = compare
        if (indexFrom <= indexTo) {
            let node = at(indexFrom)
            let node2 = at(indexTo)
            result.first = node
            result.mySize = indexTo - indexFrom + 1
            result.last = node2
        }
        return result
    }

    public func add(element: T): Unit {
        if (this.mySize == 0) {
            this.linkLast(element)
        } else if (let Some(compareMethod) <- this.compare) {
            // TODO 大于10个数以上时需要性能优化, 二分插入
            // if (this.mySize < 10) {
                var curr = this.first
                while (true) {
                    if (let Some(v) <- curr) {
                        match (compareMethod(element, v.value)) {
                            case LT =>
                                this.linkBefore(element, v)
                                return
                            case _ => ()

                        }
                        curr = v.next
                    } else {
                        this.linkLast(element)
                        break
                    }
                }
            // }
            // let middle = this.findMiddle(this.mySize)
            // var curr: ?SortListNode<T> = at(middle)
        } else {
            this.linkLast(element)
        }
    }

    public func append(element: T): Unit {
        this.linkLast(element)
    }

    public func appendAll(elements: Collection<T>): Unit {
        for (element in elements) {
            this.add(element)
        }
    }

    public func insert(index: Int64, element: T): Unit {
        if (index < 0 || index > this.mySize) {
            throw IndexOutOfBoundsException()
        }
        if (index == 0) {
            this.linkFirst(element)
        } else if (index == this.mySize - 1) {
            this.linkLast(element)
        } else {
            this.linkBefore(element, at(index))
        }
    }

    public func remove(item: T): Bool {
        var curr = this.first
        var index = 0
        if (let Some(compareMethod) <- this.compare) {
            while (let Some(v) <- curr) {
                if (compareMethod(item, v.value) == EQ && item == v.value) {
                    unlink(v)
                    return true
                }
                index++
                curr = v.next
            }
        }
        return false
    }
    public func remove(index: Int64): T {
        if (index < 0 || index >= this.mySize) {
            throw IndexOutOfBoundsException()
        }
        match (at(index)) {
            case Some(v) => this.unlink(v)
            case _ => throw IndexOutOfBoundsException()
        }
    }

    public func removeFirst(): T {
        match (first) {
            case Some(v) => this.unlinkFirst(v)
            case _ => throw IndexOutOfBoundsException()
        }
    }

    public func removeLast(): T {
        match (last) {
            case Some(v) => this.unlinkLast(v)
            case _ => throw IndexOutOfBoundsException()
        }
    }


    private func at(index: Int64): ?SortListNode<T> {
        if (index < (this.mySize >> 1)) {
            var x: ?SortListNode<T> = first
            for (_ in 0..index) {
                match (x) {
                    case Some(v) => x = v.next
                    case _ => ()
                }
            }
            x
        } else {
            var x = last
            var i = this.mySize - 1
            while (i > index) {
                match (x) {
                    case Some(v) => x = v.prev
                    case _ => ()
                }
                i--
            }
            x
        }
    }

    private func linkFirst(element: T): Unit {
        let first = this.first
        let newNode = SortListNode(prev: None<SortListNode<T>>, value: element, next: first)
        this.first = newNode
        match (first) {
            case Some(v) => v.prev = newNode
            case _ => last = newNode
        }
        this.mySize++
    }

    private func linkLast(element: T): Unit {
        let last = this.last
        let newNode = SortListNode(prev: last, value: element, next: None<SortListNode<T>>)
        this.last = newNode
        match (last) {
            case Some(v) => v.next = newNode
            case _ => first = newNode
        }
        this.mySize++
    }

    private func linkBefore(element: T, succ: ?SortListNode<T>): Unit {
        match (succ) {
            case Some(v) =>
                let pred = v.prev
                let newNode = SortListNode(prev: pred, value: element, next: succ)
                v.prev = newNode
                match (pred) {
                    case Some(v2) => v2.next = newNode
                    case _ => first = newNode
                }
                this.mySize++
            case _ => ()
        }
    }

    private func linkAfter(element: T, succ: ?SortListNode<T>): Unit {
        match (succ) {
            case Some(v) =>
                let next = v.next
                let newNode = SortListNode(prev: succ, value: element, next: next)
                v.next = newNode
                match (next) {
                    case Some(v2) => v2.prev = newNode
                    case _ => this.last = newNode
                }
                this.mySize++
            case _ => ()
        }
    }

    private func unlinkFirst(x: SortListNode<T>): T {
        let element = x.value
        let next = x.next
        x.next = None
        this.first = next
        match (next) {
            case Some(v) => v.prev = None
            case _ => last = None
        }
        this.mySize--
        element
    }

    private func unlinkLast(x: SortListNode<T>): T {
        let elements = x.value
        let prev = x.prev
        x.prev = None
        this.last = prev
        match (prev) {
            case Some(v) => v.next = None
            case _ => first = None
        }
        this.mySize--
        elements
    }

    private func unlink(x: SortListNode<T>): T {
        let element = x.value
        let next = x.next
        let prev = x.prev
        match (prev) {
            case Some(v) =>
                v.next = next
                x.prev = None
            case _ =>
                first = next
        }
        match (next) {
            case Some(v) =>
                v.prev = prev
                x.next = None
            case _ =>
                last = prev
        }
        this.mySize--
        element
    }
}

extend<T> SortedSet<T> <: ToString where T <: ToString {
    public func toString(): String {
        let buff = StringBuilder()
        var first = this.first
        var i = 0
        while (let Some(v) <- first) {
            if (i >= this.mySize) {
                break
            }
            if (i > 0) {
                buff.append(", ")
            }
            buff.append(v.value.toString())
            first = v.next
            i++
        }
        buff.append("[size = ${this.mySize}]")
        buff.toString()
    }
}

public class SortListIterator<T> <: Iterator<T> where T <: BaseDanmaku {
    var current: ?SortListNode<T>
    let size: Int64
    var index = 0
    SortListIterator(current: SortedSet<T>) {
        this.current = current.first
        this.size = current.mySize
    }

    public func next(): ?T {
        match (current) {
            case Some(v) =>
                if (index >= size) {
                    return None
                }
                let element = v.value
                current = v.next
                index++
                element
            case _ => None
        }
    }
}