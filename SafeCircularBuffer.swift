//
//  SafeCircularBuffer.swift
//  Swift6Test
//
//  Created by bobh on 5/22/25.
//

// MARK: - Circular Buffer
struct CircularBuffer<T: Sendable>: Sendable {
    let capacity: Int // Changed from private to internal (default)
    private var buffer: [T?]
    private var readIndex: Int = 0
    private var writeIndex: Int = 0
    var elementCount: Int = 0 // Changed from private to internal (default)

    init(capacity: Int) {
        precondition(capacity > 0, "Capacity must be positive")
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }

    var isEmpty: Bool {
        elementCount == 0
    }

    var isFull: Bool {
        elementCount == capacity
    }

    mutating func write(_ element: T) -> T? {
        let overwritten = buffer[writeIndex]
        buffer[writeIndex] = element

        if isFull {
            readIndex = (readIndex + 1) % capacity
        } else {
            elementCount += 1
        }

        writeIndex = (writeIndex + 1) % capacity
        return overwritten
    }

    mutating func read() -> T? {
        guard !isEmpty else { return nil }

        let element = buffer[readIndex]
        buffer[readIndex] = nil
        readIndex = (readIndex + 1) % capacity
        elementCount -= 1
        return element
    }

    func peek() -> T? {
        guard !isEmpty else { return nil }
        return buffer[readIndex]
    }

    mutating func clear() {
        buffer = Array(repeating: nil, count: capacity)
        readIndex = 0
        writeIndex = 0
        elementCount = 0
    }

    subscript(index: Int) -> T? {
        guard index >= 0, index < elementCount else { return nil }
        let adjustedIndex = (readIndex + index) % capacity
        return buffer[adjustedIndex]
    }

    func toArray() -> [T] {
        (0..<elementCount).compactMap { self[$0] }
    }

    struct Iterator: IteratorProtocol {
        private let buffer: CircularBuffer
        private var index: Int

        init(buffer: CircularBuffer) {
            self.buffer = buffer
            self.index = 0
        }

        mutating func next() -> T? {
            guard index < buffer.elementCount else { return nil }
            let element = buffer[index]
            index += 1
            return element
        }
    }

    func makeIterator() -> Iterator {
        Iterator(buffer: self)
    }
}

// MARK: - Safe Circular Buffer
actor SafeCircularBuffer<T: Sendable> {
    private var buffer: CircularBuffer<T>

    init(capacity: Int) {
        self.buffer = CircularBuffer<T>(capacity: capacity)
    }

    var isEmpty: Bool {
        buffer.isEmpty
    }

    var isFull: Bool {
        buffer.isFull
    }

    var count: Int {
        buffer.elementCount // Now accessible
    }

    func push(_ element: T) -> T? {
        buffer.write(element)
    }

    func pop() -> T? {
        buffer.read()
    }

    func peek() -> T? {
        buffer.peek()
    }

    func clear() {
        buffer.clear()
    }

    func toArray() -> [T] {
        buffer.toArray()
    }

    func pushBatch(_ elements: [T]) {
        let spaceAvailable = buffer.capacity - buffer.elementCount // Now accessible
        let elementsToWrite = min(elements.count, spaceAvailable)

        for i in 0..<elementsToWrite {
            _ = buffer.write(elements[i])
        }
    }
}
